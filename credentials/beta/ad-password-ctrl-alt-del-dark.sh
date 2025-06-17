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

        # Apply dark mode CSS
        screen = Gdk.Screen.get_default()
        provider = Gtk.CssProvider()
        css = b"""
        window {
            background-color: #1e1e1e;
        }
        dialog {
            background-color: #2e2e2e;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0px 0px 20px rgba(0,0,0,0.5);
        }
        label {
            color: #ffffff;
        }
        entry {
            background-color: #444444;
            color: #ffffff;
            font-size: 16px;
            padding: 10px;
            border-radius: 6px;
        }
        button {
            background-color: #007acc;
            color: #ffffff;
            font-size: 16px;
            padding: 10px;
            border-radius: 6px;
        }
        button:hover {
            background-color: #005f99;
        }
        """
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_ui()

    def init_ui(self):
        grid = Gtk.Grid(row_spacing=20, column_spacing=20)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        title = Gtk.Label(label="Change Your Password")
        title.set_markup("<span size='xx-large'><b>Change Your Password</b></span>")

        change_button = Gtk.Button(label="Change Password")
        change_button.connect("clicked", self.on_change_clicked)

        logout_button = Gtk.Button(label="Logout")
        logout_button.connect("clicked", lambda w: Gtk.main_quit())

        grid.attach(title, 0, 0, 2, 1)
        grid.attach(change_button, 0, 1, 1, 1)
        grid.attach(logout_button, 1, 1, 1, 1)

        self.add(grid)

    def on_change_clicked(self, button):
        dialog = PasswordDialog(self, self.user_principal)
        response = dialog.run()
        dialog.destroy()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()


class PasswordDialog(Gtk.Dialog):
    def __init__(self, parent, user_principal):
        super().__init__(title=None, transient_for=parent, flags=Gtk.DialogFlags.MODAL)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_modal(True)
        self.set_default_size(400, 300)
        self.user_principal = user_principal

        self.set_border_width(20)
        box = self.get_content_area()
        grid = Gtk.Grid(row_spacing=15, column_spacing=10)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

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

        submit_button = Gtk.Button(label="Submit")
        submit_button.connect("clicked", self.on_submit)

        grid.attach(self.current_pass, 0, 0, 1, 1)
        grid.attach(self.new_pass, 0, 1, 1, 1)
        grid.attach(self.confirm_pass, 0, 2, 1, 1)
        grid.attach(submit_button, 0, 3, 1, 1)

        box.add(grid)
        self.show_all()

    def validate_policy(self, password):
        return (len(password) >= 8 and
                re.search(r"[A-Z]", password) and
                re.search(r"[a-z]", password) and
                re.search(r"[0-9]", password))

    def on_submit(self, button):
        current = self.current_pass.get_text()
        new = self.new_pass.get_text()
        confirm = self.confirm_pass.get_text()

        if not current or not new or not confirm:
            self.show_error("All fields are required.")
            return

        if new != confirm:
            self.show_error("New password and confirmation do not match.")
            return

        if not self.validate_policy(new):
            self.show_error("Your password does not meet the policy:\nMinimum 8 characters, uppercase, lowercase, and number.")
            return

        try:
            subprocess.run(['kinit', self.user_principal], input=current.encode(), check=True, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            self.show_error("Current password incorrect.")
            return

        try:
            cmd = subprocess.Popen(['kpasswd', self.user_principal], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            input_str = f"{current}\n{new}\n{new}\n"
            out, err = cmd.communicate(input=input_str.encode())

            if cmd.returncode == 0:
                self.show_info("The password has changed successfully.\nPlease logout and login again to take effect.")
                self.response(Gtk.ResponseType.OK)
            else:
                self.show_error(f"Failed to change password:\n{err.decode()}")
        except Exception as e:
            self.show_error(str(e))
        finally:
            subprocess.run(["kdestroy"])

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

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    app = PasswordChanger()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
