from ReadWriteMemory import ReadWriteMemory
from random import randint
import requests
import json
import time
import brotli
import base64
import urllib.parse

def write_to_process(score:str):
    rwm = ReadWriteMemory()

    process = rwm.get_process_by_id('2872')
    process.open()

    value = process.get_pointer(0xFB017038F8)
    print(process.read(value))
    #process.write(value, score + 100)

def get_info():
    headers = {
        "Accept-Encoding": "gzip, deflate, br",
        "User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
    }
    resp = requests.get("https://telegram.immortal-games.online/Games/rest/stats.php/?count=3&username=mmimq", headers=headers)
    data = json.loads(resp.text)
    if data['top'][0]['username'] != "mmimq":
        print(data['top'][0]['username'])
        decode_url(int(data['top'][0]['score']))

def decode_url(score:str):
    headers = {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        "User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
        "Host": "telegram.immortal-games.online",
        "sec-ch-ua": '"Not?A_Brand";v="8", "Chromium";v="108", "Google Chrome";v="108"',

    }
    val = score + 100
    val = "uoTl9ruNQ1jgUCHFK/DTKReHzJb/SElkx9g8iYSuBag="
    val = urllib.parse.parse_qs("uoTl9ruNQ1jgUCHFK/DTKReHzJb/SElkx9g8iYSuBag".encode('utf-8'))
    print(val)
    #print(base64.b64decode(val).decode('utf-8'))
    session = requests.Session()
    session.headers = headers

    resp = session.post("https://telegram.immortal-games.online/Games/rest/init.php", data={
        "query_id": "AAE0sYAcAAAAADSxgBxX5SWz&user=%7B%22id%22%3A478196020%2C%22first_name%22%3A%22%D0%98%D0%B3%D0%BE%D1%80%D1%8C%22%2C%22last_name%22%3A%22%D0%9C%22%2C%22username%22%3A%22mmimq%22%2C%22language_code%22%3A%22en%22%7D&auth_date=1673250689&hash=16dff535decd443c3e23af2a8769e3812461e89d24ac1d4216325080ae888fd8",
        "hash": "16dff535decd443c3e23af2a8769e3812461e89d24ac1d4216325080ae888fd8",
        "username": "mmimq",
        "id":478196020
    }, headers=headers)
    print(resp.text)
    resp = session.post("https://telegram.immortal-games.online/Games/rest/set.php", headers=headers, data=val)
    print(resp.text, str(val))
    
    
if __name__ == '__main__':
    get_info()
