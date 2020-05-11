import os
from flask import Flask, request, make_response, jsonify
from flask_cors import CORS
from influxdb import InfluxDBClient
from datetime import datetime

app = Flask(__name__)
CORS(app)

class BadRequestError(Exception):
    pass

class Measurement:
    def __init__(self, request):
        try:
            params = request.get_json()
            self.__status = int(params['status'])
            self.__fr = int(params['fr'])
            self.__ie = int(params['ie'])
            self.__pause = int(params['pause'])
            self.__vc = int(params['vc'])
            self.__fio2 = int(params['fio2'])
            self.__peep = int(params['peep'])
        except KeyError as error:
            raise BadRequestError(
                    f'Debe indicar un valor para el campo {str(error)}.'
            )

    def as_dict(self):
        return {
                'status': self.__status,
                'fr': self.__fr,
                'ie': self.__ie,
                'pause': self.__pause,
                'vc': self.__vc,
                'fio2': self.__fio2,
                'peep': self.__peep
        }

@app.route('/ventilators/<ventilator_id>/measurements', methods=['POST'])
def measurement(ventilator_id):
    InfluxDBClient(
            os.environ['RECEIVER_TSDB_HOST'],
            int(os.environ['RECEIVER_TSDB_PORT']),
            os.environ['RECEIVER_TSDB_USER'],
            os.environ['RECEIVER_TSDB_PASSWORD'],
            os.environ['RECEIVER_TSDB_DB']
    ).write_points(
            [
                {
                    'measurement': 'ventilator_measurement',
                    'tags': {
                        'ventilator': '{id:02d}'.format(id=int(ventilator_id))
                    },
                    'time': datetime.utcnow().isoformat(),
                    'fields': Measurement(request).as_dict()
                }
            ]
    )
    return ('', 204)

@app.route('/reset', methods=['POST'])
def reset():
    InfluxDBClient(
            os.environ['RECEIVER_TSDB_HOST'],
            int(os.environ['RECEIVER_TSDB_PORT']),
            os.environ['RECEIVER_TSDB_USER'],
            os.environ['RECEIVER_TSDB_PASSWORD'],
            os.environ['RECEIVER_TSDB_DB']
    ).delete_series(measurement='ventilator_measurement')
    return ('', 204)

@app.errorhandler(BadRequestError)
def handle_bad_request(e):
    return make_response(
            jsonify(
                {
                    'id': 'Error de validación',
                    'description': str(e)
                }
            ),
            400
    )
