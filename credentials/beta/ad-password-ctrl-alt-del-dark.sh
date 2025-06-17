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
        """
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.username = subprocess.getoutput("logname")
        self.realm = subprocess.getoutput("realm list | awk '/realm-name/ {print $2}'")
        self.user_principal = f"{self.username}@{self.realm}"

        self.init_home_ui()

    def init_home_ui(self):
        self.clear_window()

        grid = Gtk.Grid(row_spacing=20, column_spacing=20, margin=100)
        grid.set_valign(Gtk.Align.CENTER)
        grid.set_halign(Gtk.Align.CENTER)

        lock_btn = Gtk.Button(label="Lock Screen")
        lock_btn.connect("clicked", self.on_lock_screen)

        switch_btn = Gtk.Button(label="Switch Users")
        switch_btn.connect("clicked", self.on_switch_user)

        change_btn = Gtk.Button(label="Change Password")
        change_btn.connect("clicked", self.init_change_ui)

        logout_btn = Gtk.Button(label="Sign out")
        logout_btn.connect("clicked", self.on_logout)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.get_style_context().add_class("cancel")
        cancel_btn.connect("clicked", lambda x: Gtk.main_quit())

        grid.attach(lock_btn, 0, 0, 1, 1)
        grid.attach(switch_btn, 0, 1, 1, 1)
        grid.attach(change_btn, 0, 2, 1, 1)
        grid.attach(logout_btn, 0, 3, 1, 1)
        grid.attach(cancel_btn, 0, 4, 1, 1)

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

    def validate_policy(self, password):
        return (len(password) >= 8 and
                re.search(r"[A-Z]", password) and
                re.search(r"[a-z]", password) and
                re.search(r"[0-9]", password))

    def on_lock_screen(self, button):
        try:
            subprocess.call(["gnome-screensaver-command", "-l"])
        except Exception as e:
            self.show_error(f"Lock screen failed: {e}")

    def on_switch_user(self, button):
        try:
            subprocess.run([
                "gdbus", "call", "--session",
                "--dest", "org.gnome.DisplayManager",
                "--object-path", "/org/gnome/DisplayManager/LocalDisplayFactory",
                "--method", "org.gnome.DisplayManager.LocalDisplayFactory.CreateTransientDisplay"
            ], check=True)
        except subprocess.CalledProcessError as e:
            self.show_error(f"Switch user failed: {e}")
        except FileNotFoundError:
            self.show_error("gdbus command not found.")


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
            self.show_error("Your password does not meet the policy:\nMinimum 8 characters, including uppercase, lowercase, and number.")
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
