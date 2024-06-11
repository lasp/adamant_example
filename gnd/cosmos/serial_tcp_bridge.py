#!/usr/bin/env python3

import argparse
import socket
import threading
import binascii
import serial

SYNC_PATTERN = bytearray([0xFE, 0xD4, 0xAF, 0xEE])  # Byte pattern for syncing


def setup_serial(tty, baudrate):
    seri = serial.Serial(tty, baudrate)
    return seri


def recv_from_serial(seri, sock, stop_event):
    first_time = True
    buffer = bytearray()
    while not stop_event.is_set():
        if seri.in_waiting:
            # read all available bytes
            data = seri.read(seri.in_waiting)
            buffer.extend(data)

            # find sync pattern index
            sync_idx = buffer.find(SYNC_PATTERN)

            # if we found the sync pattern in the buffer
            while sync_idx != -1:
                # exclude the first iteration
                if sync_idx != 0:

                    if not first_time:
                        # before the sync pattern is the data
                        print("tlm: " + str(binascii.hexlify(buffer[:sync_idx])))
                        sock.sendall(buffer[:sync_idx])
                    else:
                        first_time = False
                # remove processed bytes (including sync pattern)
                buffer = buffer[sync_idx + len(SYNC_PATTERN):]
                # try to find the next sync pattern
                sync_idx = buffer.find(SYNC_PATTERN)


def send_to_serial(seri, sock, stop_event):
    while not stop_event.is_set():
        data = sock.recv(2048)
        if data:
            # prepend sync pattern and write to serial port
            print("cmd: " + str(binascii.hexlify(data)))
            seri.write(SYNC_PATTERN + data)


def main(args):
    # Setup serial connection
    seri = setup_serial(args.tty, args.baudrate)
    # Setup TCP/IP connection
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((args.ip, args.port))

    # Event to signal the threads to stop
    stop_event = threading.Event()

    # Create and start threads
    recv_thread = threading.Thread(
        target=recv_from_serial, args=(seri, sock, stop_event)
    )
    send_thread = threading.Thread(target=send_to_serial, args=(seri, sock, stop_event))
    recv_thread.start()
    send_thread.start()

    try:
        # Wait for both threads to finish
        recv_thread.join()
        send_thread.join()
    except KeyboardInterrupt:
        # When Ctrl+C is pressed, signal the threads to stop
        stop_event.set()
        recv_thread.join()
        send_thread.join()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Bridge between serial device and TCP, using CCSDS 32-bit sync pattern as a delimiter over serial."
    )
    parser.add_argument("--tty", help="Path to the tty device.", required=True)
    parser.add_argument("--baudrate", help="The baud rate.", required=True, type=int)
    parser.add_argument("--ip", help="The IP address to connect to.", required=True)
    parser.add_argument(
        "--port", help="The port to connect to.", required=True, type=int
    )

    args = parser.parse_args()
    main(args)
