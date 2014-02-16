import json
import re

import requests


base = "http://cakeshow.cakecubator.com"

next_page = "/shows/2014/signups"

while next_page is not None:
    signups = requests.get(base + next_page, headers={"Accepts": "application/json"})
    next_page = None

    for link in signups.headers['link'].split(','):
        if 'rel="next"' in link:
            next_page = re.match(r'<([^>]+)>', link).group(1)

    for signup in signups.json():
        signup_class = signup["signup"]["class"]
        if signup_class == "junior" or signup_class == "child":
            print "Fixing signup {0}, {1} {2}".format(
                signup["signup"]["id"],
                signup["registrant"]["firstname"],
                signup["registrant"]["lastname"])

            response = requests.post(
                base + "/signups/" + str(signup["signup"]["id"]) + "/entries",
                headers={
                    "Content-Type": "application/json",
                    "Accepts": "application/json"
                },
                data=json.dumps({
                    "category": signup_class,
                    "didBring": False,
                    "styleChange": False
                }))

            print "Got entry id {0}".format(response.json()["id"])
