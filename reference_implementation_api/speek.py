from curses import wrapper
import curses
import socket
import struct
import json
import threading
import time
import qrcode
import os
import subprocess
import logging
from ascii_art_image import display_image

command_desc = {"/send": "Sends a message to the selected contact. Example: '/send Hello, how are you?'",
                "/showqr": "Displays the QR code of your speek id. Close by pressing 'Enter'.",
                "/switch": "Switches to another contact. Example: '/switch 1' to switch to the second contact in the list.",
                "/accept_file": "Accepts a file transfer. Example: '/accept_file 1 /folder/file_name' to accept the file with ID 1 and save it as 'file_name' in '/folder'.",
                "/reject_file": "Rejects a file transfer. Example: '/reject_file 1' to reject the file with ID 1.",
                "/cancel_file": "Cancels a file transfer. Example: '/cancel_file 1' to cancel the file with ID 1.",
                "/reject_and_block_request": "Rejects and blocks a contact request. Example: '/reject_and_block_request 1' to reject and block the contact request with ID 1.",
                "/reject_request": "Rejects a contact request. Example: '/reject_request 1' to reject the contact request with ID 1.",
                "/accept_request": "Accepts a contact request. Example: '/accept_request 1' to accept the contact request with ID 1.",
                "/send_request": "Sends a contact request. Example: '/send_request speek_id nickname my_nickname message' to send a request to the specified 'speek_id' and set the recipient's name as 'nickname'. Your name will be suggested as 'my_nickname' and a 'message' can be included.",
                "/set_nick": "Sets the nickname for a contact. Example: '/set_nick 1 nickname' to set the nickname for contact with ID 1 to 'nickname'.",
                #"/set_prune_limit": "Sets the pruning limit for the chat messages. Example: '/set_prune_limit 100' to set the prune limit to 100.",
                #"/export_identity": "Exports your identity for backup purposes. Example: '/export_identity /folder/backup_1.zip' to backup your speek indentity to '/folder/backup_1.zip'.",
                "/show_config_path": "Displays the path of the configuration folder.",
                "/show_my_speek_id": "Displays your speek id.",
                "/help": "Displays the list of commands and their descriptions.",
                "/show_contact_requests": "Displays a list of all contact requests.",
                "/quit": "Closes this application."
}

gfile_counter = 0
gcontact_request_counter = 0
gcontact_counter = 0

def replace_newlines(string):
    return string.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")

class ListDisplay:
    def __init__(self, ui, stdscr):
        self.ui = ui
        self.stdscr = stdscr
        self.shown_strings = []
        self.start_idx = 0
        self.end_idx = 0

    def show(self):
        max_y, max_x = self.stdscr.getmaxyx()
        self.end_idx = min(max_y - 2, len(self.shown_strings)*4)
        self.start_idx = 0

        self.ui.update_screen = False
        self.stdscr.clear()

        while True:
            cr_win = self.stdscr.subwin(max_y, max_x, 0, 0)
            cr_win.clear()
            cr_win.keypad(1)

            pos = 0
            for ctr, string in enumerate(self.shown_strings):
                if ctr >= self.start_idx and ctr < self.end_idx:
                    cr_win.addstr(pos, 0, string)
                    pos+=1

            cr_win.refresh()
            key = cr_win.getch()

            if key == curses.KEY_UP:
                if self.start_idx > 0:
                    self.start_idx = max(0, self.start_idx - 1)
                    self.end_idx = min(len(self.shown_strings), self.end_idx - 1)
            elif key == curses.KEY_DOWN:
                self.start_idx = min(len(self.shown_strings) - max_y + 2, self.start_idx + 1)
                self.end_idx = min(len(self.shown_strings), self.end_idx + 1)
            else:
                break

        cr_win.clear()
        cr_win.refresh()
        self.ui.update_screen = True
        self.ui.redraw_ui()

class ListContacts(ListDisplay):
    def update_shown_strings(self):
        self.shown_strings = []
        self.shown_strings.append("Navigate the list using the up and down arrow keys and close by pressing any other key.")
        self.shown_strings.append("Contact Requests:")

        for c in self.ui.contact_requests:
            if c.is_group == False:
                string = str(c.contact_request_counter) + " - Name: " + c.name
                self.shown_strings.append(string)
                string = "  | Message: " + replace_newlines(c.message)
                self.shown_strings.append(string)
                string = "  | Speek-Id-" + c.id
                self.shown_strings.append(string)

        self.shown_strings.append("Group Requests:")
        for c in self.ui.contact_requests:
            if c.is_group == True:
                string = str(c.contact_request_counter) + " - Group Name: " + c.name
                self.shown_strings.append(string)
                string = "  | Message: " + replace_newlines(c.message)
                self.shown_strings.append(string)
                string = "  | Speek-Id-" + c.id
                self.shown_strings.append(string)

class ListCommands(ListDisplay):
    def update_shown_strings(self):
        self.shown_strings = []
        self.shown_strings.append("Navigate the list using the up and down arrow keys and close by pressing any other key.")

        global command_desc

        self.shown_strings.append("Available Commands:")

        for cmd, desc in command_desc.items():
            self.shown_strings.append(cmd + ": " + desc)

class Message:
    def __init__(self, json_data, text_show, base=False):
        self.json_data = json_data
        self.identifier = json_data["identifier"]
        self.text_show = text_show
        
        if base == True:
            global gfile_counter
            self.file_counter = gfile_counter
            gfile_counter += 1

class ContactRequest:
    def __init__(self, json_data):
        self.name = json_data["name"]
        self.id = json_data["id"]
        self.message = json_data["message"]
        self.is_group = bool(json_data["is_group"])
        self.incoming_request = json_data["incoming_request"]
        
        global gcontact_request_counter
        self.contact_request_counter = gcontact_request_counter
        gcontact_request_counter += 1

class Contact:
    def __init__(self, name, uid, is_group, status):
        self.name = name
        self.id = uid
        self.is_group = is_group
        self.status = status
        self.messages = []

        global gcontact_counter
        self.contact_counter = gcontact_counter
        gcontact_counter += 1

class ChatUI:
    def __init__(self, stdscr, userlist_width=32):
        curses.start_color()
        curses.use_default_colors()
        for i in range(0, curses.COLORS):
            curses.init_pair(i, i, -1);
        self.stdscr = stdscr

        self.items = []
        global command_desc
        for cmd, desc in command_desc.items():
            self.items.append(cmd)
        
        self.update_screen = False
        self.inputbuffer = ""
        self.linebuffer = []
        self.selected_contact = None
        self.speek_id = ""
        self.log_line = ""
        self.config_location = ""
        self.contacts = []
        self.contact_requests = []
        self.height_help = 4
        self.scroll_distance = 0

        userlist_hwyx = (curses.LINES - (self.height_help + 2), userlist_width - 1, 0, 0)
        chatbuffer_hwyx = (curses.LINES - (self.height_help + 2), curses.COLS-userlist_width-1,
                           0, userlist_width + 1)
        help_hwyx = (self.height_help, curses.COLS, curses.LINES - (self.height_help + 2), 0)
        chatline_yx = (curses.LINES - 1, 0)
        self.win_userlist = stdscr.derwin(*userlist_hwyx)
        self.win_help = stdscr.derwin(*help_hwyx)
        self.win_chatline = stdscr.derwin(*chatline_yx)
        self.win_chatbuffer = stdscr.derwin(*chatbuffer_hwyx)

    def resize(self):
        """Handles a change in terminal size"""

        if not self.update_screen:
            return

        u_h, u_w = self.win_userlist.getmaxyx()
        h, w = self.stdscr.getmaxyx()

        self.win_chatline.mvwin(h - 1, 0)
        self.win_chatline.resize(1, w)

        self.win_userlist.resize(h - 2 - (self.height_help), u_w)
        self.win_chatbuffer.resize(h - 2 - (self.height_help), w - u_w - 2)

        self.win_help.mvwin(h - (self.height_help + 2), 0)
        #self.win_help.resize(4, w)

        self.linebuffer = []
        if self.selected_contact:
            for msg in self.selected_contact.messages:
                self._linebuffer_add(msg)

        self.redraw_ui()

    def redraw_ui(self):
        """Redraws the entire UI"""

        if not self.update_screen:
            return  
        
        h, w = self.stdscr.getmaxyx()
        u_h, u_w = self.win_userlist.getmaxyx()
        self.stdscr.clear()
        self.stdscr.vline(0, u_w + 1, "|", h - 2 - (self.height_help))
        self.stdscr.hline(h - 2, 0, "-", w)
        self.stdscr.refresh()

        self.redraw_userlist()
        self.redraw_chatbuffer()
        self.redraw_help()
        self.redraw_chatline()

    def redraw_help(self):
        if not self.update_screen:
            return
            
        h, w = self.win_help.getmaxyx()
        self.win_help.clear()
        if h > 1:
            self.win_help.addstr(0, 0, "To view the available commands, type /help. You can utilize the tab key for auto-completion.")
            self.win_help.addstr(1, 0, "You can navigate the chat history by scrolling up and down using the arrow keys.")
        if h > 3:
            self.win_help.addstr(2, 0, "Log: " + self.log_line)
        self.win_help.refresh()

    def redraw_chatline(self):
        """Redraw the user input textbox"""

        if not self.update_screen:
            return
            
        h, w = self.win_chatline.getmaxyx()
        self.win_chatline.clear()
        start = len(self.inputbuffer) - w + 1
        if start < 0:
            start = 0
        self.win_chatline.addstr(0, 0, self.inputbuffer[start:])
        self.win_chatline.refresh()

    def redraw_userlist(self):
        """Redraw the userlist"""

        if not self.update_screen:
            return
            
        self.win_userlist.clear()
        h, w = self.win_userlist.getmaxyx()

        line=0
        status_strings = ["Online","Offline","Request Pending","Request Rejected"]

        for status in range(4):
            for is_group in (False, True):
                first_match = False
                for c in self.contacts:
                    if c.is_group == is_group and c.status == status and line < h:
                        if not first_match:
                            self.win_userlist.addstr(line, 0, "Groups " if is_group == True else "" + status_strings[status], curses.color_pair(2))
                            first_match = True
                            line += 1

                        if line < h:
                            name = str(c.contact_counter) + " | " + c.name
                            self.win_userlist.addstr(line, 0, name[:w - 1], curses.color_pair(3 if c == self.selected_contact else 0))
                            line += 1

        self.win_userlist.refresh()

    def redraw_chatbuffer(self):
        """Redraw the chat message buffer"""

        if not self.update_screen:
            return
            
        self.win_chatbuffer.clear()
        h, w = self.win_chatbuffer.getmaxyx()
        j = len(self.linebuffer) - h - self.scroll_distance
        if j < 0:
            j = 0
        for i in range(min(h, len(self.linebuffer))):
            if self.linebuffer[j].json_data["status"] == 3 or self.linebuffer[j].json_data["status"] == 2 or self.linebuffer[j].json_data["status"] == 4:
                self.win_chatbuffer.addstr(i, 0, self.linebuffer[j].text_show, curses.color_pair(0))
            else:
                self.win_chatbuffer.addstr(i, 0, self.linebuffer[j].text_show, curses.color_pair(4))
            j += 1
        self.win_chatbuffer.refresh()

    def chatbuffer_add(self, json_data):
        """
        Add a message to the chat buffer, automatically slicing it to
        fit the width of the buffer
        """

        already_exists = False
        for c in self.contacts:
            if c.id == json_data["from_id"]:
                for m in c.messages:
                    if m.identifier == json_data["identifier"]:
                        m.json_data = json_data
                        m.text_show = json_data["plaintext"]
                        already_exists = True
                        break
                if not already_exists:      
                    msgc = Message(json_data, json_data["plaintext"], True)
            
                    c.messages.append(msgc)
                    if json_data["from_id"] == self.selected_contact.id:
                        self._linebuffer_add(msgc)
        if not already_exists:
            self.redraw_chatbuffer()
            self.redraw_chatline()
            self.win_chatline.cursyncup()
        else:
            self.resize()

    def _linebuffer_add(self, msgc):
        msg = ""
        if int(msgc.json_data["type"]) == 0:
            msg = msgc.json_data["plaintext"]
            if not msgc.json_data["is_fully_received"]:
               msg = "Receiving Message: " + msgc.json_data["prep_text"] + "%"
        elif int(msgc.json_data["type"]) == 1:
            bytes_str = ""
            if msgc.json_data["transferStatus"] == 1 or msgc.json_data["transferStatus"] == 2 or msgc.json_data["transferStatus"] == 4:
                if msgc.json_data["bytesTransferred"] > 0:
                    bytes_str += str(msgc.json_data["bytesTransferred"])+"/"
                    bytes_str += str(msgc.json_data["fileSize"]) + " Bytes "
                    percentage = int(int(msgc.json_data["bytesTransferred"]) / int(msgc.json_data["fileSize"]) * 100)
                    bar = "[" + "=" * int(percentage / 4) + ">" + " " * (25 - int(percentage / 4)) + "]"
                    bytes_str += bar
                else:
                    bytes_str += str(msgc.json_data["fileSize"]) + " Bytes"

            elif msgc.json_data["transferStatus"] == 3:
                bytes_str = "Rejected"
            elif msgc.json_data["transferStatus"] == 5:
                bytes_str = "Cancelled"
            elif msgc.json_data["transferStatus"] == 6:
                bytes_str = "Complete"
            elif msgc.json_data["transferStatus"] == 7:
                bytes_str = "Unkown Failure"
            elif msgc.json_data["transferStatus"] == 8:
                bytes_str = "Bad File Hash"
            elif msgc.json_data["transferStatus"] == 9:
                bytes_str = "Network Error"
            elif msgc.json_data["transferStatus"] == 10:
                bytes_str = "File System Error"
            msg = "File Transfer <" + str(msgc.file_counter) + ">: " + msgc.json_data["fileName"] + " / " + bytes_str
        elif int(msgc.json_data["type"]) == 2:
            msg = "Image <" + str(msgc.file_counter) + ">"
            msg += " <" + msgc.json_data["image_caption"] + ">"

        if msgc.json_data["status"] == 3 or msgc.json_data["status"] == 2 or msgc.json_data["status"] == 4:
            if msgc.json_data["status"] == 4:
                msg = "Me> " + msg + " (✓✓)"
            else:
                msg = "Me> " + msg
        else:
            for c in self.contacts:
                if c.id == msgc.json_data["from_id"]:
                    msg = c.name + "> " + msg

        h, w = self.stdscr.getmaxyx()
        u_h, u_w = self.win_userlist.getmaxyx()
        w = w - u_w - 2
        for msg0 in msg.split("\n"):
            while len(msg0) >= w:
                self.linebuffer.append(Message(msgc.json_data, msg0[:w]))
                msg0 = msg[w:]
            if msg0:
                self.linebuffer.append(Message(msgc.json_data, msg0))

    def prompt(self, msg):
        """Prompts the user for input and returns it"""
        self.inputbuffer = msg
        self.redraw_chatline()
        res = self.wait_input()
        res = res[len(msg):]
        return res

    def wait_input(self, prompt=""):
        """
        Wait for the user to input a message and hit enter.
        Returns the message
        """
        self.inputbuffer = prompt
        self.redraw_chatline()
        self.win_chatline.cursyncup()
        last = -1
        while last != ord('\n'):
            last = self.stdscr.getch()
            if last == ord('\n'):
                tmp = self.inputbuffer
                self.inputbuffer = ""
                self.redraw_chatline()
                self.win_chatline.cursyncup()
                return tmp[len(prompt):]
            elif last == curses.KEY_BACKSPACE or last == 127:
                if len(self.inputbuffer) > len(prompt):
                    self.inputbuffer = self.inputbuffer[:-1]
            elif last == curses.KEY_RESIZE:
                self.resize()
            elif last == 9: # TAB key
                self.inputbuffer = self.autocomplete(self.inputbuffer)
            elif last == curses.KEY_UP:
                self.scroll_distance += 1
                scoll_log_line = "Info: Scrolling up in chat history"
                if self.scroll_distance > 0:
                    self.log_line = scoll_log_line
                else:
                    if self.log_line == scoll_log_line:
                        self.log_line = ""
                self.redraw_help()
                self.redraw_chatbuffer()
            elif last == curses.KEY_DOWN:
                self.scroll_distance -= 1 if self.scroll_distance > 0 else 0
                if self.scroll_distance > 0:
                    self.log_line = scoll_log_line
                else:
                    if self.log_line == scoll_log_line:
                        self.log_line = ""
                self.redraw_help()
                self.redraw_chatbuffer()
            elif 32 <= last <= 126:
                self.inputbuffer += chr(last)
            self.redraw_chatline()

    def autocomplete(self, inputbuffer):
        """
        Returns the autocompleted input string
        """
        suggestions = []
        for item in self.items:
            if item.startswith(inputbuffer):
                suggestions.append(item)
        if len(suggestions) == 1:
            return suggestions[0]
        elif len(suggestions) > 1:
            common_prefix = os.path.commonprefix(suggestions)
            return common_prefix
        return inputbuffer



def read_all_messages(socket, stop_flag):
    try:
        # Read the version of the data stream
        version = struct.unpack('!I', socket.recv(4))[0]
        
        # Read the size of the message
        block_size = struct.unpack('!I', socket.recv(4))[0]

        # Read the data of the message
        block = b''
        while len(block) < block_size and not stop_flag.is_set():
            block += socket.recv(block_size - len(block))

        data_decoded = block.decode('utf-8-sig', 'ignore')

        return json.loads(data_decoded)
    except:
        return json.loads('{}')
    
def receive_updates(ipc_socket, stop_flag, ui, torStatus):
    while not stop_flag.is_set():
        json_data = read_all_messages(ipc_socket, stop_flag)
        if stop_flag.is_set():
            break
        if "status" in json_data and json_data["status"] == "fail":
            if json_data["com"] == "getId":
                ui.log_line = "Error: " + json_data["reason"]
        else:
            if "what" in json_data:
                if json_data["what"] == "message_update":
                    ui.chatbuffer_add(json_data)
                elif json_data["what"] == "contact_request":
                    ui.contact_requests.append(ContactRequest(json_data))
                elif json_data["what"] == "contact_request_removed":
                    ui.contact_requests = [item for item in ui.contact_requests if item.id != json_data["id"]]
                elif json_data["what"] == "tor_status_changed":
                    torStatus.torStatus = json_data;
                    ui.resize()
                elif json_data["what"] == "update_contact_status":
                    for c in ui.contacts:
                        if json_data["id"] == c.id:
                            c.name = json_data["name"]
                            c.status = json_data["status"]
                            c.is_group = json_data["is_group"]
                    ui.redraw_userlist()
            elif "com" in json_data:
                if json_data["com"] == "getId":
                    ui.speek_id = json_data["id"]
                elif json_data["com"] == "getConfigLocation":
                    ui.config_location = json_data["config_location"]
                elif json_data["com"] == "getContacts":
                    if "out" in json_data:
                        ui.contacts.clear()
                        for c in json_data["out"]:
                            ui.contacts.append(Contact(c["name"], c["id"], c["is_group"], c["status"]))
                        ui.selected_contact = ui.contacts[8]
                        ui.redraw_userlist()

def write_message(socket, data, version=19):
    # Encode the data
    encoded_data = data.encode('utf-8-sig')

    # Combine the version, message size and message into a single bytearray
    combined = bytearray(struct.pack('!I', version)) + bytearray(struct.pack('!I', len(encoded_data))) + bytearray(encoded_data)

    # Write the combined data
    socket.sendall(combined)

class torStatus:
    def __init__(self, stdscr):
        self.torStatus = json.loads("{}")
        self.stdscr = stdscr

    def show(self):
        try:
            curses.curs_set(0)
        except:
            pass

        start_time = time.time()
        while "progress" not in self.torStatus or self.torStatus["progress"] < 100:
            if "progress" not in self.torStatus:
                if time.time() - start_time > 10:
                    raise Exception("Timeout reached while waiting for IPC Tor status response")
            else:
                h, w = self.stdscr.getmaxyx()
                loading_bar = "Starting Tor: " + self.torStatus["summary"]

                loading_bar_start_y = h // 2 - 3
                loading_bar_start_x = w // 2 - len(loading_bar) // 2

                progress = self.torStatus["progress"]

                self.stdscr.clear()
                self.stdscr.attron(curses.color_pair(1))
                self.stdscr.addstr(loading_bar_start_y, loading_bar_start_x, loading_bar)
                self.stdscr.attroff(curses.color_pair(1))

                loading_bar_fill = "[" + "=" * int(progress/4) + ">" + " " * (25-int(progress/4)) + "]"
                loading_bar_fill_start_y = loading_bar_start_y + 1
                loading_bar_fill_start_x = w // 2 - len(loading_bar_fill) // 2

                self.stdscr.attron(curses.color_pair(3))
                self.stdscr.addstr(loading_bar_fill_start_y, loading_bar_fill_start_x, loading_bar_fill)
                self.stdscr.attroff(curses.color_pair(3))

                status_string = "Loading... " + str(progress) + "%"
                status_string_start_y = loading_bar_start_y + 3
                status_string_start_x = w // 2 - len(status_string) // 2
                self.stdscr.attron(curses.color_pair(2))
                self.stdscr.addstr(status_string_start_y, status_string_start_x, status_string)
                self.stdscr.attroff(curses.color_pair(2))

                self.stdscr.refresh()
            time.sleep(0.05)
        try:
            curses.curs_set(1)
        except:
            pass

def main(stdscr):
    logging.basicConfig(filename='Speek-Curses.log', level=logging.DEBUG)

    tor_status = torStatus(stdscr)

    stdscr.clear()
    ui = ChatUI(stdscr)

    try:
        ipc_endpoint = "/tmp/SpeekServerIPC"
        ipc_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        stop_flag = threading.Event()
        t = threading.Thread(target=receive_updates, args=(ipc_socket, stop_flag, ui, tor_status))

        start_process = False

        if start_process:
            # Start the subprocess
            p = subprocess.Popen(["./speek"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Wait for the IPC endpoint file to become available
        start_time = time.time()
        while not os.path.exists(ipc_endpoint):
            if time.time() - start_time > 5:
                raise Exception("Timeout reached while waiting for IPC endpoint file")
            time.sleep(0.1)

        # Connect to the QLocalServer
        ipc_socket.connect(ipc_endpoint)
        
        # Start the thread
        t.start()

        if start_process:
            tor_status.show()

        ui.update_screen = True
        ui.redraw_ui()
        
        write_message(ipc_socket, '{"com":"getContacts"}')
        write_message(ipc_socket, '{"com":"getAllMessages"}')
        write_message(ipc_socket, '{"com":"getAllContactRequests"}')
        write_message(ipc_socket, '{"com":"getId"}')
        write_message(ipc_socket, '{"com":"getConfigLocation"}')

        contact_requests_display = ListContacts(ui, stdscr)
        commands_display = ListCommands(ui, stdscr)
    
        inp = ""
        while inp != "/quit":
            inp = ui.wait_input()
            try:
                com, val = inp.split(" ", 1) if " " in inp else (inp, "")
                json_c = json.loads('{}')
                if com == "/send" or com == "/send_ascii_art":
                    json_c["com"] = "sendMessage"
                    json_c["id"] = ui.selected_contact.id
                    if com == "/send_ascii_art":
                        if val == "smiley":
                            json_c["message"] = "\n      _____\n    .'     '.\n   /  o   o  \\\n  |           |\n  |  \\     /  |\n   \\  '---'  /\n    '._____.'"
                        else:
                            raise "command ascii art does not exist"
                    else:
                        json_c["message"] = val
                    write_message(ipc_socket, json.dumps(json_c))
                elif com == "/reject_file" or com == "/cancel_file" or com == "/accept_file":
                    if com == "/reject_file":
                        json_c["com"] = "rejectFileTransfer"
                    elif com == "/cancel_file":
                        json_c["com"] = "cancelFileTransfer"
                    elif com == "/accept_file":
                        json_c["com"] = "acceptFileTransfer"

                    json_c["id"] = ui.selected_contact.id
                    
                    if com == "/accept_file":
                        file_id, destination = val.split(" ", 1)
                        json_c["destination"] = destination
                    else:
                        file_id = val

                    for m in ui.selected_contact.messages:
                        if hasattr(m, "file_counter") and m.file_counter == int(file_id):
                            json_c["file_id"] = int(m.identifier)
                            break
                    if "file_id" in json_c:
                        write_message(ipc_socket, json.dumps(json_c))
                elif com == "/reject_and_block_request" or com == "/reject_request" or com == "/accept_request":
                    if com == "/reject_request":
                        json_c["com"] = "refuseContactRequest"
                    elif com == "/reject_and_block_request":
                        json_c["com"] = "refuseContactRequestAndBlockUser"
                    else:
                        json_c["com"] = "acceptContactRequest"

                    contact_req_list_id = -1
                    if com == "/accept_request":
                        contact_req_list_id, contact_name = val.split(" ", 1)
                        json_c["nickname"] = contact_name
                    else:
                        contact_req_list_id = val

                    for c in ui.contact_requests:
                        if c.contact_request_counter == int(contact_req_list_id):
                            json_c["id"] = c.id
                            break

                    if "id" in json_c:
                        write_message(ipc_socket, json.dumps(json_c))
                elif com == "/send_request":
                    pass
                elif com == "/set_nick":
                    pass
                elif com == "/set_prune_limit":
                    pass
                elif com == "/export_identity":
                    pass
                elif com == "/show_config_path":
                    ui.log_line = ui.config_location
                    ui.redraw_help()
                elif com == "/show_my_speek_id":
                    ui.log_line = ui.speek_id
                    ui.redraw_help()
                elif com == "/help":
                    commands_display.update_shown_strings()
                    commands_display.show()
                elif com == "/switch":
                    for c in ui.contacts:
                        if c.contact_counter == int(val):
                            ui.selected_contact = c
                            ui.redraw_userlist()
                            break
                elif com == "/show_contact_requests":
                    contact_requests_display.update_shown_strings()
                    contact_requests_display.show()
                elif com == "/show_image":
                    ui.update_screen = False
                    stdscr.clear()

                    image_b64 = ""
                    for m in ui.selected_contact.messages:
                        if hasattr(m, "file_counter") and m.file_counter == int(val) and m.json_data["type"] == 2:
                            image_b64 = m.json_data["image"]
                    
                    if image_b64 != "":
                        display_image(stdscr, image_b64)
                        ui.update_screen = True
                        ui.redraw_ui()
                    else:
                        ui.update_screen = True
                        ui.log_line = "Error: Not a valid image."
                        ui.resize()
                elif com == "/showqr":
                    max_y, max_x = stdscr.getmaxyx()
                    qr = qrcode.QRCode(
                        version=1,
                        box_size=1,
                        border=0,
                    )
                    qr.add_data(ui.speek_id + ";" + "Speek-User")
                    qr.make(fit=True)
                    qr_matrix = qr.get_matrix()
                    qr_height = len(qr_matrix)
                    qr_width = len(qr_matrix[0])
                    start_row = (max_y - qr_height) // 2
                    start_col = (max_x - qr_width) // 2
                    if qr_height <= max_y and qr_width <= max_x:
                        ui.update_screen = False
                        stdscr.clear()
                        for i, row in enumerate(qr_matrix):
                            for j, col in enumerate(row):
                                if col:
                                    stdscr.addstr(start_row + i, start_col + j * 2, u'\u2588'u'\u2588')
                                else:
                                    stdscr.addstr(start_row + i, start_col + j * 2, "  ")
                    else:
                        ui.log_line = "Error: Terminal size insufficient for QR code. Increase terminal size."
                    stdscr.refresh()
                    stdscr.getkey()
                    
                    ui.update_screen = True
                    ui.redraw_ui()
            except Exception as e:
                ui.update_screen = True
                logging.exception("An error occured:")
    except Exception as e:
        logging.exception("An error occured2:")
    except KeyboardInterrupt:
        pass
    finally:
        if start_process:
            p.communicate(input=b'quit\n')
        time.sleep(0.2)
        stop_flag.set()
        ipc_socket.shutdown(socket.SHUT_RDWR)
        ipc_socket.close()
        if start_process:
            p.terminate()
            p.wait()

wrapper(main)
curses.endwin()
try:
    curses.curs_set(1)
except:
    pass