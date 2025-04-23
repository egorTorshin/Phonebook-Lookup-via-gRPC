import sys
import grpc
import gRPC_pb2 as pb2
import gRPC_pb2_grpc as pb2_grpc
from colorama import init, Fore, Style

# Initialize colorama
init(autoreset=True)

class PhonebookClient:
    def __init__(self, host: str = "localhost", port: int = 50051, connect_timeout: float = 5.0):
        self.address = f"{host}:{port}"
        self.channel = grpc.insecure_channel(self.address)
        try:
            grpc.channel_ready_future(self.channel).result(timeout=connect_timeout)
        except grpc.FutureTimeoutError:
            print(Fore.RED + f"ERROR: Cannot connect to server at {self.address}")
            sys.exit(1)
        self.stub = pb2_grpc.PhonebookStub(self.channel)

    def add_contact(self, name: str, number: str) -> pb2.Response:
        req = pb2.Contact(name=name, number=number)
        return self.stub.AddContact(req)

    def get_contact(self, name: str):
        req = pb2.Name(name=name)
        try:
            return self.stub.GetContact(req)
        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.NOT_FOUND:
                return None
            raise

    def delete_contact(self, name: str):
        req = pb2.Name(name=name)
        try:
            return self.stub.DeleteContact(req)
        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.NOT_FOUND:
                return None
            raise

    def list_contacts(self):
        resp = self.stub.ListContacts(pb2.Empty())
        return resp.contacts

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Phonebook gRPC client")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", default=50051, type=int)
    args = parser.parse_args()

    client = PhonebookClient(host=args.host, port=args.port)

    help_msg = (
        Fore.CYAN + "Commands:\n" +
        "  add <name> <number>   – Add or update contact\n" +
        "  get <name>            – Retrieve contact\n" +
        "  delete <name>         – Delete contact\n" +
        "  list                  – List all contacts\n" +
        "  exit                  – Quit client\n"
    )
    print(help_msg)

    while True:
        try:
            line = input(Fore.YELLOW + "> " + Style.RESET_ALL).strip()
        except (EOFError, KeyboardInterrupt):
            print(Fore.MAGENTA + "\nGoodbye.")
            break

        if not line:
            continue
        parts = line.split()
        cmd, *params = parts

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
            break
        else:
            print(help_msg)

if __name__ == "__main__":
    main()
