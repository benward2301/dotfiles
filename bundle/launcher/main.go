package main

import (
	"archive/tar"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/klauspost/compress/zstd"
)

const magic = "DEVTOOLS"

const usage = `usage: devtools <command>
       devtools [-v | --version] [-h | --help]

commands:
  install       unpack the bundle and install it for this user
  extract       unpack the bundle only, and print where it went
  manifest      list the bundled tools and their versions

options:
  -v, --version  print the bundle id
  -h, --help     print this help
`

type payload struct {
	id       string
	manifest string
	offset   int64
	size     int64
	file     *os.File
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}
	var err error
	switch os.Args[1] {
	case "pack":
		if len(os.Args) != 6 {
			err = errors.New("usage: devtools pack PAYLOAD MANIFEST ID OUT")
			break
		}
		err = pack(os.Args[2], os.Args[3], os.Args[4], os.Args[5])
	case "install":
		err = install(os.Args[2:])
	case "extract":
		var dir string
		if dir, err = extract(); err == nil {
			fmt.Println(dir)
		}
	case "-v", "--version":
		var p *payload
		if p, err = openPayload(); err == nil {
			fmt.Println(p.id)
		}
	case "manifest":
		var p *payload
		if p, err = openPayload(); err == nil {
			fmt.Print(p.manifest)
		}
	case "help", "-h", "--help":
		fmt.Print(usage)
	default:
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "devtools:", err)
		os.Exit(1)
	}
}

func pack(payloadPath, manifestPath, id, out string) error {
	self, err := os.Executable()
	if err != nil {
		return err
	}
	manifest, err := os.ReadFile(manifestPath)
	if err != nil {
		return err
	}
	dst, err := os.OpenFile(out, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o755)
	if err != nil {
		return err
	}
	defer dst.Close()
	for _, path := range []string{self, payloadPath} {
		if err := appendFile(dst, path); err != nil {
			return err
		}
	}
	info, err := os.Stat(payloadPath)
	if err != nil {
		return err
	}
	trailer := append(manifest, id...)
	trailer = binary.BigEndian.AppendUint64(trailer, uint64(info.Size()))
	trailer = binary.BigEndian.AppendUint32(trailer, uint32(len(manifest)))
	trailer = binary.BigEndian.AppendUint16(trailer, uint16(len(id)))
	trailer = append(trailer, magic...)
	if _, err := dst.Write(trailer); err != nil {
		return err
	}
	return dst.Close()
}

func appendFile(dst io.Writer, path string) error {
	src, err := os.Open(path)
	if err != nil {
		return err
	}
	defer src.Close()
	_, err = io.Copy(dst, src)
	return err
}

func openPayload() (*payload, error) {
	self, err := os.Executable()
	if err != nil {
		return nil, err
	}
	f, err := os.Open(self)
	if err != nil {
		return nil, err
	}
	info, err := f.Stat()
	if err != nil {
		return nil, err
	}
	fixed := int64(8 + 4 + 2 + len(magic))
	tail := make([]byte, fixed)
	if info.Size() < fixed {
		return nil, errors.New("no payload attached; build this with bundle/build")
	}
	if _, err := f.ReadAt(tail, info.Size()-fixed); err != nil {
		return nil, err
	}
	if string(tail[14:]) != magic {
		return nil, errors.New("no payload attached; build this with bundle/build")
	}
	size := int64(binary.BigEndian.Uint64(tail[0:8]))
	manifestLen := int64(binary.BigEndian.Uint32(tail[8:12]))
	idLen := int64(binary.BigEndian.Uint16(tail[12:14]))
	meta := make([]byte, manifestLen+idLen)
	metaOffset := info.Size() - fixed - int64(len(meta))
	if _, err := f.ReadAt(meta, metaOffset); err != nil {
		return nil, err
	}
	return &payload{
		id:       string(meta[manifestLen:]),
		manifest: string(meta[:manifestLen]),
		offset:   metaOffset - size,
		size:     size,
		file:     f,
	}, nil
}

func (p *payload) fingerprint() (string, error) {
	if p.size < 8 {
		return "", errors.New("payload is too small")
	}
	tail := make([]byte, 8)
	if _, err := p.file.ReadAt(tail, p.offset+p.size-8); err != nil {
		return "", err
	}
	return fmt.Sprintf("%d-%x", p.size, tail), nil
}

func dataHome() (string, error) {
	if dir := os.Getenv("XDG_DATA_HOME"); dir != "" {
		return filepath.Join(dir, "devtools"), nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".local", "share", "devtools"), nil
}

func extract() (string, error) {
	p, err := openPayload()
	if err != nil {
		return "", err
	}
	base, err := dataHome()
	if err != nil {
		return "", err
	}
	dir := filepath.Join(base, p.id)
	fingerprint, err := p.fingerprint()
	if err != nil {
		return "", err
	}
	if done, err := os.ReadFile(filepath.Join(dir, ".complete")); err == nil && string(done) == fingerprint {
		return dir, nil
	}
	if err := os.MkdirAll(base, 0o755); err != nil {
		return "", err
	}
	tmp, err := os.MkdirTemp(base, p.id+".partial-")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(tmp)

	fmt.Fprintf(os.Stderr, "Unpacking %s into %s\n", p.id, dir)
	progress := &progressReader{r: io.NewSectionReader(p.file, p.offset, p.size), total: p.size}
	dec, err := zstd.NewReader(progress)
	if err != nil {
		return "", err
	}
	defer dec.Close()
	if err := untar(dec, tmp); err != nil {
		return "", err
	}
	fmt.Fprintln(os.Stderr)
	if err := os.WriteFile(filepath.Join(tmp, ".complete"), []byte(fingerprint), 0o644); err != nil {
		return "", err
	}
	if err := os.RemoveAll(dir); err != nil {
		return "", err
	}
	if err := os.Rename(tmp, dir); err != nil {
		return "", err
	}
	return dir, nil
}

func untar(r io.Reader, dest string) error {
	tr := tar.NewReader(r)
	type dirTime struct {
		path string
		time time.Time
	}
	var dirs []dirTime
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		name := filepath.Clean(hdr.Name)
		if name == "." {
			continue
		}
		if filepath.IsAbs(name) || name == ".." || strings.HasPrefix(name, "../") {
			return fmt.Errorf("unsafe path in payload: %s", hdr.Name)
		}
		target := filepath.Join(dest, name)
		mode := hdr.FileInfo().Mode().Perm() | 0o200
		switch hdr.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, mode|0o700); err != nil {
				return err
			}
			dirs = append(dirs, dirTime{target, hdr.ModTime})
		case tar.TypeReg:
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			f, err := os.OpenFile(target, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, mode)
			if err != nil {
				return err
			}
			if _, err := io.Copy(f, tr); err != nil {
				f.Close()
				return err
			}
			if err := f.Close(); err != nil {
				return err
			}
			if err := os.Chtimes(target, hdr.ModTime, hdr.ModTime); err != nil {
				return err
			}
		case tar.TypeSymlink:
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			if err := os.Symlink(hdr.Linkname, target); err != nil {
				return err
			}
		case tar.TypeLink:
			if err := os.Link(filepath.Join(dest, filepath.Clean(hdr.Linkname)), target); err != nil {
				return err
			}
		default:
			return fmt.Errorf("unsupported entry in payload: %s", hdr.Name)
		}
	}

	for i := len(dirs) - 1; i >= 0; i-- {
		if err := os.Chtimes(dirs[i].path, dirs[i].time, dirs[i].time); err != nil {
			return err
		}
	}
	return nil
}

type progressReader struct {
	r         io.Reader
	total     int64
	done      int64
	lastShown int64
}

func (p *progressReader) Read(b []byte) (int, error) {
	n, err := p.r.Read(b)
	p.done += int64(n)
	if pct := p.done * 100 / p.total; pct != p.lastShown || err == io.EOF {
		p.lastShown = pct
		fmt.Fprintf(os.Stderr, "\r  %3d%%", pct)
	}
	return n, err
}

func install(args []string) error {
	dir, err := extract()
	if err != nil {
		return err
	}
	script := filepath.Join(dir, "install")
	env := append(os.Environ(), "BUNDLE_DIR="+dir)
	return syscall.Exec(script, append([]string{script}, args...), env)
}
