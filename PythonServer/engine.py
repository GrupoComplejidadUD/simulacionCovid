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
def getData():
    lugares_contagios = {
        "transporte": 0,
        "trabajo": 0,
        "casa": 0,
        "sin definir": 0
    }

    estrato_socioeconomico = {
        "1": 0,
        "2": 0,
        "3": 0,
        "4": 0,
        "5": 0,
        "6": 0
    }
    result = mongo.db['dias']
    collection_dias = result.find({})
    output = []
    tiempo_promedio_ida = []
    tiempo_promedio_vuelta = []
    total_muertes = 0
    total_contagios = 0
    variables_semilla = ""

    for document in collection_dias:
        if document['dia'] == 0:
            variables_semilla = document['variablesSemilla']

        variable_dia = document['variablesGlobales']
        if len(variable_dia) > 1:
            determinar_lugares_contagio_estrato(document, lugares_contagios, estrato_socioeconomico)
            muertos_inicio = variable_dia[0]['inicio']['muertos']
            muertos_fin = variable_dia[1]['fin']['muertos']
            contagiados_inicio = variable_dia[0]['inicio']['contagiados']
            contagiados_fin = variable_dia[1]['fin']['contagiados']
            contagiados_por_dia = contagiados_fin - contagiados_inicio
            muertes_por_dia = muertos_fin - muertos_inicio
            total_muertes = total_muertes + muertes_por_dia
            total_contagios = total_contagios + contagiados_por_dia
            personas = document['personas']
            data_frame_personas = pandas.DataFrame(personas)
            tiempo_promedio_ida.append(data_frame_personas['tiempoPromedioViajeAlTrabajoValor'].mean())
            tiempo_promedio_vuelta.append(data_frame_personas['tiempoPromedioViajeACasaValor'].mean())
            output.append({'dia': document['dia'], 'muertos': muertes_por_dia, "contagiados": contagiados_por_dia})

    data_frame_dias = pandas.DataFrame(output, columns=['dia', 'muertos'])
    mean = data_frame_dias.mean()

    total_promedio_ida = pandas.DataFrame(tiempo_promedio_ida, columns=['tiempo']).mean()
    total_promedio_vuelta = pandas.DataFrame(tiempo_promedio_vuelta, columns=['tiempo']).mean()

    return jsonify({
        'result': output,
        'mean': mean.to_json(),
        'promViajeIda': total_promedio_ida['tiempo'],
        'promViajeVuelta': total_promedio_vuelta['tiempo'],
        "muertesTotal": total_muertes,
        "contagiosTotal": total_contagios,
        "lugaresContagio": lugares_contagios,
        "estratoSocioeconomico" : estrato_socioeconomico,
        "variablesSemilla": variables_semilla
    })


def determinar_lugares_contagio_estrato(documento, lugares_contagios, estrato_socioeconomico):
    list_personas = documento['personas']
    for persona in list_personas:

        if persona["infectada?"] and persona["tiempo-infectado"] < 1440:
            actualizar_valores_diccionario(lugares_contagios, persona, "lugarInfeccion")
            actualizar_valores_diccionario(estrato_socioeconomico, persona, "estratoSocial")


def actualizar_valores_diccionario(diccionario, persona, atributo):
    persona_atributo = str(persona[atributo])
    valor = diccionario.get(persona_atributo)
    diccionario.update({persona_atributo: valor + 1})


if __name__ == '__main__':
    app.run(debug=True)
