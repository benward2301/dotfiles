
options.force_256_colors = False

options.color_default = ''
options.color_default_hdr = 'bold'
options.color_bottom_hdr = 'underline'
options.color_column_sep = 'bright_black'
options.color_current_col = 'bold'
options.color_key_col = 'cyan'
options.color_hidden_col = 'bright_black'
options.color_selected_row = 'yellow'
options.color_note_row = 'yellow'
options.color_note_type = 'yellow'
options.color_note_pending = 'bold green'

options.color_status = 'bold black on cyan'
options.color_keystrokes = 'bold black on cyan'
options.color_active_status = 'black on blue'
options.color_inactive_status = 'bright_black'
options.color_top_status = 'underline'
options.color_longname_status = 'black on cyan'
options.color_longname_guide = 'bright_black'
options.color_guide_unwritten = 'bright_black'
options.color_error = 'red'
options.color_warning = 'yellow'
options.color_working = 'green'
options.color_highlight_status = 'black on green'

options.color_menu = 'black on blue'
options.color_menu_active = 'yellow on black'
options.color_menu_spec = 'black on green'
options.color_menu_help = 'black on blue'
options.color_cmdpalette = 'black on cyan'
options.color_sidebar = 'black on cyan'
options.color_sidebar_title = 'black on yellow'
options.color_code = 'bold'

options.color_edit_unfocused = 'black on cyan'
options.color_edit_cell = 'black on white'
options.color_readonly = 'on bright_black'
options.color_highlight_search = 'black on yellow'
options.color_aggregator = 'bold on bright_black'
options.color_graph_hidden = 'bright_black'

from visidata import BaseSheet
BaseSheet.unbindkey("Ctrl+D")
import visidata.experimental.vimcompat

from visidata import Sheet
Sheet.unbindkey('$')
Sheet.bindkey('0', 'go-leftmost')
Sheet.bindkey('$', 'go-rightmost')

BaseSheet.unbindkey('U')
Sheet.unbindkey('u')
Sheet.bindkey('u', 'undo-last')
Sheet.bindkey('U', 'unselect-row')

from visidata import vd
from visidata.menu import main_menu

class _HotChar(str):
    def __new__(cls, ch, hot):
        s = super().__new__(cls, ch)
        s._hot = hot
        return s
    def isupper(self):
        return self._hot

class _HotTitle(str):
    def __new__(cls, title, hotidx):
        s = super().__new__(cls, title)
        s._hotidx = hotidx
        return s
    def __iter__(self):
        return (_HotChar(c, i == self._hotidx) for i, c in enumerate(str.__str__(self)))

for _m in vd.menus:
    if _m.title == 'Plot':
        _m.title = _HotTitle('Plot', 3)
main_menu.pop('p', None)
main_menu['t'] = 'Plot'
BaseSheet.unbindkey('Alt+p')
BaseSheet.bindkey('Alt+t', 'menu-plot')

Sheet.bindkey('Esc', 'highlight-clear')
