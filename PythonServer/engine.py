from flask import Flask
from flask import jsonify
from flask import request
from flask_pymongo import PyMongo
import pandas
from flask_cors import CORS

# create the flask object
app = Flask(__name__)

app.config['MONGO_DBNAME'] = 'SimulacionCovid'
app.config['MONGO_URI'] = 'mongodb://localhost:27017/SimulacionCovid'

CORS(app)

mongo = PyMongo(app)

@app.route('/data', methods=['GET'])
def hello():
    result = mongo.db['dias']
    cursor = result.find({})
    output = []
    tiempoPromedioIda = []
    tiempoPromedioVuelta = []
    totalMuertes = 0
    totalContagios = 0

    for s in cursor:
        variableDia = s['variablesGlobales']
        if len(variableDia) > 1:
            muertosInicio = variableDia[0]['inicio']['muertos']
            muertosFin = variableDia[1]['fin']['muertos']
            contagiadosInicio = variableDia[0]['inicio']['contagiados']
            contagiadosFin = variableDia[1]['fin']['contagiados']
            contagiadosPorDia = contagiadosFin - contagiadosInicio
            muertesPorDia = muertosFin - muertosInicio
            totalMuertes = totalMuertes + muertesPorDia
            totalContagios = totalContagios + contagiadosPorDia
            personas = s['personas']
            dataFramePersonas = pandas.DataFrame(personas)
            tiempoPromedioIda.append(dataFramePersonas['tiempoPromedioViajeAlTrabajo'].mean())
            tiempoPromedioVuelta.append(dataFramePersonas['tiempoPromedioViajeACasa'].mean())
            output.append({'dia': s['dia'], 'muertos': muertesPorDia, "contagiados" : contagiadosPorDia})

    dataFrameDias = pandas.DataFrame(output, columns= ['dia', 'muertos'])
    mean = dataFrameDias.mean()

    totalPromedioIda = pandas.DataFrame(tiempoPromedioIda, columns= ['tiempo']).mean()
    totalPromedioVuelta = pandas.DataFrame(tiempoPromedioVuelta, columns= ['tiempo']).mean()

    return jsonify({
        'result' : output, 
        'mean' : mean.to_json(), 
        'promViajeIda' : totalPromedioIda['tiempo'], 
        'promViajeVuelta' : totalPromedioVuelta['tiempo'], 
        "muertesTotal": totalMuertes,
        "contagiosTotal": totalContagios
    })

if __name__ == '__main__':
    app.run(debug=True)