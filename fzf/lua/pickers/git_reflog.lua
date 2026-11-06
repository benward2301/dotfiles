return {
  command = [[git reflog]],

  output = [[awk '{print $1}']],
}
