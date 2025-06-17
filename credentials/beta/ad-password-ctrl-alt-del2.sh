#!/usr/bin/env python3
import gi
import subprocess
import re

sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 krb5-user

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class PasswordChanger(Gtk.Window):
    def __init__(self):
        super().__init__(title="Change Password")
        self.set_default_size(600, 400)
        self.fullscreen()
        self.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#a53c6f"))

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_ui()

    def init_ui(self):
        grid = Gtk.Grid(row_spacing=10, column_spacing=10, margin=50)
        grid.set_column_homogeneous(False)
        grid.set_row_homogeneous(False)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        self.current_pass = Gtk.Entry()
        self.current_pass.set_placeholder_text("Enter your current password")
        self.current_pass.set_visibility(False)

        self.new_pass = Gtk.Entry()
        self.new_pass.set_placeholder_text("Enter your new password")
        self.new_pass.set_visibility(False)

        self.confirm_pass = Gtk.Entry()
        self.confirm_pass.set_placeholder_text("Confirm your new password")
        self.confirm_pass.set_visibility(False)

        change_btn = Gtk.Button(label="Change Password")
        change_btn.connect("clicked", self.on_change_password)

        grid.attach(self.current_pass, 0, 0, 1, 1)
        grid.attach(self.new_pass, 0, 1, 1, 1)
        grid.attach(self.confirm_pass, 0, 2, 1, 1)
        grid.attach(change_btn, 0, 3, 1, 1)

        self.add(grid)

    def validate_policy(self, password):
        if len(password) < 8:
            return False
        if not re.search(r"[A-Z]", password): return False
        if not re.search(r"[a-z]", password): return False
        if not re.search(r"[0-9]", password): return False
        return True

    def on_change_password(self, button):
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
            self.show_error("Your password does not meet the policy:\nMin 8 chars, uppercase, lowercase, and digit.")
            return

        # Validate current password
        try:
            subprocess.run(['kinit', self.user_principal], input=current.encode(), check=True, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            self.show_error("Current password incorrect.")
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
                self.show_info("The password has changed successfully.\nPlease logout and login again to take effect.")
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
    app = PasswordChanger()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
