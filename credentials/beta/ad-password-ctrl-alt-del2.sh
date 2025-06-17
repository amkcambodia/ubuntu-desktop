#!/usr/bin/env python3
import gi
import subprocess
import re
import signal

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class PasswordDialog(Gtk.Dialog):
    def __init__(self, parent, user_principal):
        super().__init__(title="Change Your Password", transient_for=parent, flags=0)
        self.set_default_size(400, 300)
        self.user_principal = user_principal

        self.set_modal(True)
        self.set_resizable(False)

        box = self.get_content_area()
        grid = Gtk.Grid(row_spacing=15, column_spacing=10, margin=20)
        box.add(grid)

        self.current_pass = Gtk.Entry()
        self.current_pass.set_placeholder_text("Enter your current password")
        self.current_pass.set_visibility(False)
        self.current_pass.set_hexpand(True)
        grid.attach(Gtk.Label(label="Current Password:"), 0, 0, 1, 1)
        grid.attach(self.current_pass, 1, 0, 1, 1)

        self.new_pass = Gtk.Entry()
        self.new_pass.set_placeholder_text("Enter your new password")
        self.new_pass.set_visibility(False)
        self.new_pass.set_hexpand(True)
        grid.attach(Gtk.Label(label="New Password:"), 0, 1, 1, 1)
        grid.attach(self.new_pass, 1, 1, 1, 1)

        self.confirm_pass = Gtk.Entry()
        self.confirm_pass.set_placeholder_text("Confirm your new password")
        self.confirm_pass.set_visibility(False)
        self.confirm_pass.set_hexpand(True)
        grid.attach(Gtk.Label(label="Confirm Password:"), 0, 2, 1, 1)
        grid.attach(self.confirm_pass, 1, 2, 1, 1)

        btn_change = Gtk.Button(label="Change Password")
        btn_change.connect("clicked", self.on_change_password)
        grid.attach(btn_change, 0, 3, 2, 1)

        self.message_label = Gtk.Label()
        self.message_label.set_halign(Gtk.Align.CENTER)
        self.message_label.set_valign(Gtk.Align.CENTER)
        self.message_label.set_line_wrap(True)
        grid.attach(self.message_label, 0, 4, 2, 1)

        self.show_all()

    def validate_policy(self, password):
        if len(password) < 8:
            return False
        if not re.search(r"[A-Z]", password):
            return False
        if not re.search(r"[a-z]", password):
            return False
        if not re.search(r"[0-9]", password):
            return False
        return True

    def on_change_password(self, button):
        current = self.current_pass.get_text()
        new = self.new_pass.get_text()
        confirm = self.confirm_pass.get_text()

        if not current or not new or not confirm:
            self.message_label.set_text("All fields are required.")
            return

        if new != confirm:
            self.message_label.set_text("New password and confirmation do not match.")
            return

        if not self.validate_policy(new):
            self.message_label.set_text(
                "Your password is not meet password policy:\nMinimum 8 characters, uppercase, lowercase, and number."
            )
            return

        # Validate current password with kinit
        try:
            subprocess.run(['kinit', self.user_principal], input=current.encode(), check=True, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            self.message_label.set_text("Current password incorrect. Please try again.")
            return

        # Attempt to change password
        try:
            cmd = subprocess.Popen(['kpasswd', self.user_principal],
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
            input_str = f"{current}\n{new}\n{new}\n"
            out, err = cmd.communicate(input=input_str.encode())

            if cmd.returncode == 0:
                self.message_label.set_text("The password has changed successfully.\nPlease logout and login again to take effect.")
            else:
                self.message_label.set_text(f"Failed to change password:\n{err.decode()}")
        except Exception as e:
            self.message_label.set_text(str(e))
        finally:
            subprocess.run(["kdestroy"])


class PasswordChanger(Gtk.Window):
    def __init__(self):
        super().__init__(title="User Options")
        self.fullscreen()  # Fullscreen window like Windows change password screen
        self.connect("key-press-event", self.on_key_press)

        # Style
        screen = Gdk.Screen.get_default()
        provider = Gtk.CssProvider()
        css = b"""
        window {
            background-color: #B0C4DE;
        }
        button {
            font-size: 22px;
            padding: 25px;
            min-width: 250px;
        }
        """
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_ui()

    def init_ui(self):
        grid = Gtk.Grid(row_spacing=50, column_spacing=0)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        self.btn_change = Gtk.Button(label="Change Password")
        self.btn_change.connect("clicked", self.on_change_password_clicked)

        self.btn_logout = Gtk.Button(label="Logout")
        self.btn_logout.connect("clicked", self.on_logout_clicked)

        grid.attach(self.btn_change, 0, 0, 1, 1)
        grid.attach(self.btn_logout, 0, 1, 1, 1)

        self.add(grid)

    def on_change_password_clicked(self, button):
        dialog = PasswordDialog(self, self.user_principal)
        dialog.run()
        dialog.destroy()

    def on_logout_clicked(self, button):
        # Call logout command, adjust depending on your environment
        subprocess.run(["gnome-session-quit", "--logout", "--no-prompt"])
        Gtk.main_quit()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()


if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)  # Allow Ctrl+C to exit
    app = PasswordChanger()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
