import requests, json
from functools import wraps
from flask import Flask, request, current_app
app = Flask(__name__)

def jsonp(func):
    """Wraps JSONified output for JSONP requests."""
    @wraps(func)
    def decorated_function(*args, **kwargs):
        callback = request.args.get('callback', False)
        if callback:
            content = str(callback) + '(' + str(func(*args,**kwargs)) + ')'
            print callback
            print content
            mimetype = 'application/javascript'
            return current_app.response_class(content, mimetype=mimetype)
        else:
            return func(*args, **kwargs)
    return decorated_function

@app.route("/api/politician/<string:postcode>")
@jsonp
def get_politician(postcode):
	api_key = 'GyHsCnCyb9szFm2q9MBZTA2j'
	error = 'error'
	response = {}
	r = requests.get('http://mapit.mysociety.org/postcode/' + postcode)
	location = r.json()
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
	d = json.dumps(response)
	return d

if __name__ == "__main__":
    app.run(host='0.0.0.0')


