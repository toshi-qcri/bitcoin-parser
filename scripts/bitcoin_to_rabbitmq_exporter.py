import json
import os

import pika

QUEUE_NAME = "blockchain.bitcoin"

host = os.getenv("RABBITMQ_HOST")
port = int(os.getenv("RABBITMQ_PORT")) if os.getenv("RABBITMQ_PORT") else None
virtual_host = os.getenv("RABBITMQ_VIRTUAL_HOST")
user = os.getenv("RABBITMQ_USER")
password = os.getenv("RABBITMQ_PASSWORD")
credentials = pika.PlainCredentials(user, password)
parameters = pika.ConnectionParameters(host, port, virtual_host, credentials)

connection = None


def open_connection():
    global connection
    if not connection:
        connection = pika.BlockingConnection(parameters=parameters)
    return connection


def close_connection():
    global connection
    if connection:
        connection.close()


def get_channel():
    conn = open_connection()
    channel = conn.channel()
    channel.queue_declare(queue=QUEUE_NAME)

    return channel


def publish(item):
    channel = get_channel()
    channel.basic_publish(exchange='', routing_key=QUEUE_NAME, body=item)


def main():
    buffer = dict()
    with open("blocks.json", "r") as f:
        blocks = f.read().replace("\n", ",")[:-1].strip()
        blocks = "[" + blocks + "]"
        blocks = json.loads(blocks)
        for block in blocks:
            block_no = int(block["number"])
            buffer[block_no] = block

    with open("enriched_transactions.json", "r") as f:
        transactions = f.read().replace("\n", ",")[:-1].strip()
        transactions = "[" + transactions + "]"
        transactions = json.loads(transactions)
        for tx in transactions:
            block_no = int(tx["block_number"])
            if block_no in buffer:
                if "tx" in buffer[block_no]:
                    buffer[block_no]["tx"].append(tx)
                else:
                    buffer[block_no]["tx"] = [tx]

    for item in buffer:
        publish(item)
    close_connection()


if __name__ == "__main__":
    main()
