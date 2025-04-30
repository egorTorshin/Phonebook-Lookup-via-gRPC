import sys
import grpc
import gRPC_pb2 as pb2
import gRPC_pb2_grpc as pb2_grpc
from colorama import init, Fore, Style

init(autoreset=True)

class PhonebookClient:
    """
    gRPC client for the Phonebook service.
    Manages connection setup, stub creation, and provides CRUD operations.
    """
    def __init__(self, host: str = "localhost", port: int = 50051, connect_timeout: float = 5.0):
        """
        Establish a gRPC channel to the server and ensure it’s ready within a timeout.
        Exits the program if the server cannot be reached.
        """
        self.address = f"{host}:{port}"
        # Create an insecure (TCP) channel to the server address
        self.channel = grpc.insecure_channel(self.address)
        try:
            # Wait until the channel is ready, or raise a timeout error
            grpc.channel_ready_future(self.channel).result(timeout=connect_timeout)
        except grpc.FutureTimeoutError:
            # If the server is unreachable, inform the user and terminate
            print(Fore.RED + f"ERROR: Cannot connect to server at {self.address}")
            sys.exit(1)
        # Instantiate the generated stub to call RPC methods
        self.stub = pb2_grpc.PhonebookStub(self.channel)

    def add_contact(self, name: str, number: str) -> pb2.Response:
        """
        Add a new contact or update an existing one.
        Returns a Response containing a status message.
        """
        req = pb2.Contact(name=name, number=number)
        return self.stub.AddContact(req)

    def get_contact(self, name: str):
        """
        Retrieve a contact by name.
        Returns the Contact message if found, or None if not.
        """
        req = pb2.Name(name=name)
        try:
            return self.stub.GetContact(req)
        except grpc.RpcError as e:
            # Translate NOT_FOUND into Python None for easier handling
            if e.code() == grpc.StatusCode.NOT_FOUND:
                return None
            # Re-raise unexpected errors
            raise

    def delete_contact(self, name: str):
        """
        Delete a contact by name.
        Returns a Response if deleted, or None if the contact was not found.
        """
        req = pb2.Name(name=name)
        try:
            return self.stub.DeleteContact(req)
        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.NOT_FOUND:
                return None
            raise

    def list_contacts(self):
        """
        List all contacts in the phonebook.
        Returns a list of Contact messages.
        """
        resp = self.stub.ListContacts(pb2.Empty())
        return resp.contacts

def main():
    """
    Command‐line interface for interacting with the PhonebookClient.
    Supports add, get, delete, list, and exit commands.
    """
    import argparse
    parser = argparse.ArgumentParser(description="Phonebook gRPC client")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", default=50051, type=int)
    args = parser.parse_args()

    # Instantiate the client, attempting connection immediately
    client = PhonebookClient(host=args.host, port=args.port)

    # User guidance printed in cyan for visibility
    help_msg = (
        Fore.CYAN + "Commands:\n" +
        "  add <name> <number>   – Add or update contact\n" +
        "  get <name>            – Retrieve contact\n" +
        "  delete <name>         – Delete contact\n" +
        "  list                  – List all contacts\n" +
        "  exit                  – Quit client\n"
    )
    print(help_msg)

    # Interactive prompt loop
    while True:
        try:
            # Prompt in yellow; reset style for user input
            line = input(Fore.YELLOW + "> " + Style.RESET_ALL).strip()
        except (EOFError, KeyboardInterrupt):
            # Graceful exit on Ctrl+D or Ctrl+C
            print(Fore.MAGENTA + "\nGoodbye.")
            break

        if not line:
            # Skip empty inputs
            continue
        parts = line.split()
        cmd, *params = parts

        # Dispatch based on command and parameter count
        if cmd == "add" and len(params) == 2:
            resp = client.add_contact(*params)
            print(Fore.GREEN + resp.message)
        elif cmd == "get" and len(params) == 1:
            contact = client.get_contact(params[0])
            if contact:
                print(Fore.GREEN + f"{contact.name}: {contact.number}")
            else:
                print(Fore.RED + "Contact not found.")
        elif cmd == "delete" and len(params) == 1:
            resp = client.delete_contact(params[0])
            if resp:
                print(Fore.GREEN + resp.message)
            else:
                print(Fore.RED + "Contact not found.")
        elif cmd == "list" and not params:
            contacts = client.list_contacts()
            if contacts:
                for c in contacts:
                    print(Fore.GREEN + f"{c.name}: {c.number}")
            else:
                print(Fore.YELLOW + "No contacts.")
        elif cmd in ("exit", "quit"):
            # Exit loop on user’s request
            break
        else:
            # Unrecognized input: reprint help
            print(help_msg)

if __name__ == "__main__":
    main()
