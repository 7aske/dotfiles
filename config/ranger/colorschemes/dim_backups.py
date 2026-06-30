# Stock "default" colorscheme, extended to gray out backup files that the
# dim_backups plugin tags with the "backup" context.
from __future__ import (absolute_import, division, print_function)

from ranger.colorschemes.default import Default
from ranger.gui.color import black, white, bold, dim, BRIGHT


class Scheme(Default):
    def use(self, context):
        fg, bg, attr = Default.use(self, context)

        if context.in_browser and getattr(context, 'backup', False) \
                and not context.selected \
                and not (context.cut or context.copied):
            attr |= bold
            fg = black + BRIGHT
            # Fall back to dim white on terminals without bright colors.
            if BRIGHT == 0:
                attr |= dim
                fg = white

        return fg, bg, attr
