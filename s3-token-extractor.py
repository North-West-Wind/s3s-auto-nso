"""
Extract gToken and bulletToken for Splatoon 3 NSO.
The result will be saved in the current folder.

Run as follows: mitmdump -s s3_token_extractor.py '~u GetWebServiceToken | ~u bullet_tokens'
"""

import logging
import json


def handle_web_service_token(obj):
    return 'gToken {}'.format(obj["result"]["accessToken"])


def handle_bullet_token(obj):
    return 'bulletToken {}'.format(obj["bulletToken"])


class Splatoon3TokenExtractor:
    def __init__(self):
        self.outfile = open("gtoken_bullettoken.txt", "w")

    def extract_tokens(self, flow, cb):
        logging.info(f"{flow.response}")
        body = flow.response.content.decode('utf-8')
        obj = json.loads(body)
        output = cb(obj)
        logging.info(output)
        self.outfile.write(output + '\n')
        self.outfile.flush()

    def response(self, flow):
        path = flow.request.path
        if path.endswith('GetWebServiceToken'):
            self.extract_tokens(flow, handle_web_service_token)
        if path.endswith('bullet_tokens'):
            self.extract_tokens(flow, handle_bullet_token)


addons = [Splatoon3TokenExtractor()]