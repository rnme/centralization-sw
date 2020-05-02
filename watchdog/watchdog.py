import os
import asyncio
from datetime import datetime, timedelta
from influxdb import InfluxDBClient

class Measurement:
    def __init__(self, point):
        self.__ventilator = point[0][1]['ventilator']
        self.__point = next(point[1])

    def ventilator(self):
        return self.__ventilator

    def is_older_than(self, seconds):
        return datetime.strptime(
                self.__point['time'], "%Y-%m-%dT%H:%M:%S.%fZ"
        ) < (datetime.utcnow() - timedelta(seconds=60))


class Measurements:
    def __init__(self, result_set):
        self.__result_set = result_set

    def measurements(self):
        return list(
                map(lambda point: Measurement(point), self.__result_set.items())
        )

async def watch():
    client = InfluxDBClient(
            os.environ['WATCHDOG_TSDB_HOST'],
            int(os.environ['WATCHDOG_TSDB_PORT']),
            os.environ['WATCHDOG_TSDB_USER'],
            os.environ['WATCHDOG_TSDB_PASSWORD'],
            os.environ['WATCHDOG_TSDB_DB']
    )
    while True:
        print('Obteniendo mediciones...')
        latest = Measurements(
                client.query(
                    '''
                        SELECT "status", "fr", "ie", "pause", "vc", "fio2", "peep"
                        FROM "ventilator_measurement"
                        GROUP BY "ventilator"
                        ORDER BY time DESC
                        LIMIT 1
                    '''
                )
        )
        for measurement in latest.measurements():
            if measurement.is_older_than(
                    int(os.environ['WATCHDOG_DELTA'])
            ):
                print(f'El respirador {measurement.ventilator()} está desconectado.')
                client.write_points(
                    [
                        {
                            'measurement': 'ventilator_measurement',
                            'tags': {
                                'ventilator': measurement.ventilator()
                            },
                            'time': datetime.utcnow().isoformat(),
                            'fields': { 'status': -1 }
                        }
                    ]
            )
        await asyncio.sleep(int(os.environ['WATCHDOG_PERIOD']))

asyncio.run(watch())
