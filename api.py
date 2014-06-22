import requests, json
from flask import Flask
app = Flask(__name__)

@app.route("/api/politician/<string:postcode>")
def get_politician(postcode):
	api_key = 'GyHsCnCyb9szFm2q9MBZTA2j'
	#postcode = "eh91qw"
	r = requests.get('http://mapit.mysociety.org/postcode/' + postcode)
	location = r.json()
	response = {}
	response['lat'] = location['wgs84_lat']
	response['long'] = location['wgs84_lon']
	area_id = 0
	for area in location['areas']:
		if location['areas'][area]['type'] == 'SPC':
			area_id = area
			break
	geojson = requests.get('http://mapit.mysociety.org/area/' + str(area_id) + ".geojson")
	response['outline'] = geojson.json()
	response['constituency'] = requests.get('http://mapit.mysociety.org/area/' + str(area_id) + ".json").json()['name']
	theyworkforyou = 'http://www.theyworkforyou.com/api/getMSP?key=%s&constituency=%s&output=js' % (api_key, response['constituency'])
	r = requests.get(theyworkforyou)
	response['politician'] = r.json()[0]
	return json.dumps(response)

if __name__ == "__main__":
    app.run()


