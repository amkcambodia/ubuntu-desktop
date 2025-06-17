#!/usr/bin/env python3
import gi
import subprocess
import re
import signal

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class PasswordChangeDialog(Gtk.Dialog):
    def __init__(self, parent, user_principal):
        super().__init__(title="Change your password", transient_for=parent, flags=Gtk.DialogFlags.MODAL)
        self.set_default_size(500, 300)
        self.set_resizable(False)
        self.user_principal = user_principal

        self.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                         "Change Password", Gtk.ResponseType.OK)

        self.connect("key-press-event", self.on_key_press)

        box = self.get_content_area()
        grid = Gtk.Grid(row_spacing=20, column_spacing=20, margin=30)
        box.add(grid)

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

        grid.attach(self.current_pass, 0, 0, 1, 1)
        grid.attach(self.new_pass, 0, 1, 1, 1)
        grid.attach(self.confirm_pass, 0, 2, 1, 1)

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

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.response(Gtk.ResponseType.CANCEL)

    def run_and_change_password(self):
        response = self.run()
        if response == Gtk.ResponseType.OK:
            current = self.current_pass.get_text()
            new = self.new_pass.get_text()
            confirm = self.confirm_pass.get_text()

            if not current or not new or not confirm:
                self.show_error("All fields are required.")
                return False

            if new != confirm:
                self.show_error("New password and confirmation do not match.")
                return False

            if not self.validate_policy(new):
                self.show_error(
                    "Your password does not meet the policy:\nMinimum 8 characters, uppercase, lowercase, and number."
                )
                return False

            # Validate current password
            try:
                subprocess.run(['kinit', self.user_principal], input=current.encode(), check=True, stderr=subprocess.PIPE)
            except subprocess.CalledProcessError:
                self.show_error("Current password incorrect.")
                return False

            # Attempt to change password
            try:
                cmd = subprocess.Popen(['kpasswd', self.user_principal],
                                       stdin=subprocess.PIPE,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE)
                input_str = f"{current}\n{new}\n{new}\n"
                out, err = cmd.communicate(input=input_str.encode())

                if cmd.returncode == 0:
                    self.show_info("The password has changed successfully.\nPlease logout and login again to take effect.")
                    self.destroy()
                    return True
                else:
                    self.show_error(f"Failed to change password:\n{err.decode()}")
                    return False
            except Exception as e:
                self.show_error(str(e))
                return False
            finally:
                subprocess.run(["kdestroy"])

        else:
            self.destroy()
            return False

    def show_error(self, message):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Error")
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def show_info(self, message):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "Success")
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

class PasswordChanger(Gtk.Window):
    def __init__(self):
        super().__init__(title="User Options")
        self.set_default_size(400, 200)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("key-press-event", self.on_key_press)

        # Set background color via CSS
        screen = Gdk.Screen.get_default()
        provider = Gtk.CssProvider()
        css = b"""
        window {
            background-color: #B0C4DE;
        }
        button {
            font-size: 18px;
            padding: 15px;
            min-width: 180px;
        }
        """
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_ui()

    def init_ui(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20, margin=50)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)

        self.btn_change = Gtk.Button(label="Change Password")
        self.btn_change.connect("clicked", self.on_change_password_clicked)

        self.btn_logout = Gtk.Button(label="Logout")
        self.btn_logout.connect("clicked", self.on_logout_clicked)

        box.pack_start(self.btn_change, False, False, 0)
        box.pack_start(self.btn_logout, False, False, 0)

        self.add(box)

    def on_change_password_clicked(self, button):
        dialog = PasswordChangeDialog(self, self.user_principal)
        dialog.run_and_change_password()

    def on_logout_clicked(self, button):
        # Logout the user gracefully
        subprocess.run(["gnome-session-quit", "--logout", "--no-prompt"])
        # fallback (or on other DEs) you can use:
        # subprocess.run(["pkill", "-KILL", "-u", self.username])

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)  # Ctrl+C works
    app = PasswordChanger()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
