#!/usr/bin/env python3
import gi
import subprocess
import re
import signal

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class PasswordChanger(Gtk.Window):
    def __init__(self):
        super().__init__(title="Change Password")
        self.set_default_size(800, 600)
        self.fullscreen()
        self.connect("key-press-event", self.on_key_press)

        # Apply dark mode and minimal shadow
        screen = Gdk.Screen.get_default()
        provider = Gtk.CssProvider()
        css = b"""
        window {
            background-color: #1e1e1e;
        }
        label {
            color: #ffffff;
        }
        entry {
            background-color: #2a2a2a;
            color: #ffffff;
            font-size: 16px;
            padding: 12px;
            border-radius: 6px;
            border: 1px solid #555;
        }
        button {
            background-image: none;
            background-color: #1e1e1e;
            color: #ffffff;
            font-size: 16px;
            padding: 12px 24px;
            border-radius: 8px;
            border: none;
            box-shadow: 0 1px 2px rgba(255, 255, 255, 0.1);
            margin: 5px;
        }
        button:hover {
            background-color: #444444;
            box-shadow: 0 1px 3px rgba(255, 255, 255, 0.2);
        }
        button.cancel {
            background-color: #333333;
            box-shadow: 0 1px 2px rgba(255, 255, 255, 0.1);
        }
        button.cancel:hover {
            background-color: #555555;
            box-shadow: 0 1px 3px rgba(255, 255, 255, 0.2);
        }
        dialog {
            background-color: #1e1e1e;
        }
        dialog label, dialog * {
            color: #ffffff;
        }
        """
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_home_ui()

    def apply_dark_css(self, widget):
        css = b"""
        * {
            background-color: #1e1e1e;
            color: #ffffff;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        context = widget.get_style_context()
        context.add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        # Apply also to internal content area (important!)
        if isinstance(widget, Gtk.Dialog):
            content_area = widget.get_content_area()
            content_area.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            for child in content_area.get_children():
                child.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


    def init_home_ui(self):
        self.clear_window()

        grid = Gtk.Grid(row_spacing=20, column_spacing=20, margin=100)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        lock_btn = Gtk.Button(label="Lock Screen")
        lock_btn.connect("clicked", self.on_lock_screen)

        change_btn = Gtk.Button(label="Change Password")
        change_btn.connect("clicked", self.init_change_ui)

        logout_btn = Gtk.Button(label="Sign out")
        logout_btn.connect("clicked", self.on_logout)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.get_style_context().add_class("cancel")
        cancel_btn.connect("clicked", lambda x: Gtk.main_quit())

        grid.attach(lock_btn, 0, 0, 1, 1)
        grid.attach(change_btn, 0, 1, 1, 1)
        grid.attach(logout_btn, 0, 2, 1, 1)
        grid.attach(cancel_btn, 0, 3, 1, 1)

        self.add(grid)
        self.show_all()

    def init_change_ui(self, button):
        self.clear_window()

        grid = Gtk.Grid(row_spacing=15, column_spacing=15, margin=100)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        title = Gtk.Label()
        title.set_markup("<span font='22' foreground='#ffffff'><b>Change Your Password</b></span>")

        self.current_pass = Gtk.Entry()
        self.current_pass.set_placeholder_text("Enter your current password")
        self.current_pass.set_visibility(False)
        self.current_pass.set_width_chars(30)

        self.new_pass = Gtk.Entry()
        self.new_pass.set_placeholder_text("Enter your new password")
        self.new_pass.set_visibility(False)
        self.new_pass.set_width_chars(30)

        self.confirm_pass = Gtk.Entry()
        self.confirm_pass.set_placeholder_text("Confirm your new password")
        self.confirm_pass.set_visibility(False)
        self.confirm_pass.set_width_chars(30)

        change_btn = Gtk.Button(label="Change Password")
        change_btn.connect("clicked", self.on_change_password)

        back_btn = Gtk.Button(label="Back")
        back_btn.connect("clicked", lambda x: self.init_home_ui())

        # Connect Enter key (activate) to change password on all password entries
        self.current_pass.connect("activate", self.on_change_password)
        self.new_pass.connect("activate", self.on_change_password)
        self.confirm_pass.connect("activate", self.on_change_password)

        grid.attach(title,         0, 0, 2, 1)
        grid.attach(self.current_pass, 0, 1, 2, 1)
        grid.attach(self.new_pass,     0, 2, 2, 1)
        grid.attach(self.confirm_pass, 0, 3, 2, 1)
        grid.attach(change_btn,    0, 4, 1, 1)
        grid.attach(back_btn,      1, 4, 1, 1)

        self.add(grid)
        self.show_all()

    def clear_window(self):
        for child in self.get_children():
            self.remove(child)

    def on_lock_screen(self, button):
        try:
            subprocess.call(["gnome-screensaver-command", "-l"])
        except Exception as e:
            self.show_error(f"Lock screen failed: {e}")

    def on_change_password(self, widget):
        current = self.current_pass.get_text()
        new = self.new_pass.get_text()
        confirm = self.confirm_pass.get_text()

        if not current or not new or not confirm:
            self.show_error("All fields are required.")
            return

        if new != confirm:
            self.show_error("New password and confirmation do not match.")
            return

        try:
            subprocess.run(['kinit', self.user_principal], input=current.encode(), check=True, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            self.show_error("Current password incorrect.")
            return

        try:
            cmd = subprocess.Popen(['kpasswd', self.user_principal],
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
            input_str = f"{current}\n{new}\n{new}\n"
            out, err = cmd.communicate(input=input_str.encode())

            if cmd.returncode == 0:
                self.show_info("The password has changed successfully.\nPlease logout and login again to take effect.")
            else:
                ad_msg = err.decode().strip() or out.decode().strip()
                self.show_error(f"Failed to change password:\n{ad_msg}")
        except Exception as e:
            self.show_error(str(e))
        finally:
            subprocess.run(["kdestroy"])

    def show_error(self, message):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Error")
        self.apply_dark_css(dialog)
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def show_info(self, message):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "Success")
        self.apply_dark_css(dialog)
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def on_logout(self, button):
        subprocess.call(["gnome-session-quit", "--logout", "--no-prompt"])

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    app = PasswordChanger()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
