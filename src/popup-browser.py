#!/usr/bin/env python3
import gi, sys
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, Gdk, WebKit2, GLib
url = sys.argv[1] if len(sys.argv) > 1 else "about:blank"
win = Gtk.Window(title="popup-browser", decorated=False, default_width=800, default_height=600)
win.set_wmclass("floating", "floating")
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
ctx = WebKit2.WebContext.get_default()
ctx.set_tls_errors_policy(WebKit2.TLSErrorsPolicy.IGNORE)
webview = WebKit2.WebView.new_with_context(ctx)
webview.load_uri(url)
win.add(webview)
def on_key_press(widget, event):
    if event.keyval == Gdk.KEY_Escape:
        Gtk.main_quit()
win.connect("key-press-event", on_key_press)
win.connect("destroy", Gtk.main_quit)
def grab():
    win.grab_focus()
    return False
win.show_all()
win.present()
GLib.idle_add(grab)
Gtk.main()

