import requests, json
from flask import Flask
app = Flask(__name__)

@app.route("/api/politician/?postcode=<string:postcode>")
def get_politician(postcode):
	api_key = 'GyHsCnCyb9szFm2q9MBZTA2j'
	error = 'error'
	response = {}
	r = requests.get('http://mapit.mysociety.org/postcode/' + postcode)
	location = r.json()
	print location
	if error in location:
		return 'postcode not valid with error: %s' % location[error]
	response['lat'] = location['wgs84_lat']
	response['long'] = location['wgs84_lon']
	area_id = 0
	for area in location['areas']:
		if location['areas'][area]['type'] == 'SPC':
			area_id = area
			break
	geojson = requests.get('http://mapit.mysociety.org/area/' + str(area_id) + ".geojson").json()
	constituency = requests.get('http://mapit.mysociety.org/area/' + str(area_id) + ".json").json()
	if error in geojson:
		return 'mapit api query failed with error: %s' % geojson[error]
	if error in constituency:
		return 'mapit api query failed with error: %s' % constituency[error]
	response['constituency'] = constituency['name']
	response['outline'] = geojson
	
	theyworkforyou = 'http://www.theyworkforyou.com/api/getMSP?key=%s&constituency=%s&output=js' % (api_key, response['constituency'])
	politician = requests.get(theyworkforyou).json()
	if error in politician:
		return 'theyworkforyou api query failed with error: %s' % politican[error]
	response['politician'] = politician[0]
	return json.dumps(response)

if __name__ == "__main__":
    app.run(host='0.0.0.0')


