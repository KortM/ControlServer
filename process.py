from ReadWriteMemory import ReadWriteMemory
from random import randint
import requests
import json
import time

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
        write_to_process(int(data['top'][0]['score']))
        
if __name__ == '__main__':
    while True:
        get_info()
        time.sleep(10)
