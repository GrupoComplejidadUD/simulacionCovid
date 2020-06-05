import pymongo
from pymongo import MongoClient
import ast
import subprocess

dataBaseName = "SimulacionCovid"
dataBaseUrl = "localhost"
dataBasePort = 27017
globalDict = {}
valores_semilla = {}


def getDataBaseClient():
    cliente = MongoClient(dataBaseUrl, dataBasePort)

    return cliente


def resetDataBase(nombreColeccion):
    clientDataBase = getDataBaseClient()[dataBaseName]
    clientDataBase.drop_collection(nombreColeccion)


def updateDict(key, value):
    globalDict.update({key:value})


def resetDict():
    globalDict.clear()

def update_variables_semilla(key, value):
    valores_semilla.update({key:value})

def add_variables_semilla_to_globalDict(nombre_key):
    updateDict(nombre_key, valores_semilla)

def reset_variables_semilla():
    valores_semilla.clear()


def insertarDictMongo(nombreColeccion):
    coleccion = getCollection(nombreColeccion)
    coleccion.insert_one(globalDict)


def getCollection(nombreColeccion):
    return getDataBaseClient()[dataBaseName][nombreColeccion]


def agregarPersona(id, nombreColeccion):
    filtro, actualizacion = {"_id": id}, {"$addToSet": {"personas": globalDict}}
    updateOne(filtro, actualizacion, nombreColeccion)


def actualizar_lugar_infeccion(id, id_persona, nombre_coleccion, lugar_infeccion):
    filtro, actualizacion = {"_id": id, "personas._id": id_persona}, {"$set": {"personas.$.lugarInfeccion": lugar_infeccion}}
    updateOne(filtro, actualizacion, nombre_coleccion)


def agregarInformacionDia(id, nombreColeccion, variable):
    filtro, actualizacion = {"_id": id}, {"$addToSet": {"variablesGlobales": {variable : globalDict}}}
    updateOne(filtro, actualizacion, nombreColeccion)


def updateOne(filtro, actualizacion, nombreColeccion):
    coleccion = getCollection(nombreColeccion)
    coleccion.update_one(filtro, actualizacion)

def get_probabilidad_acumulada():
    result = getDataBaseClient()[dataBaseName]['dias']
    cursor = result.find({}, {'personas':0})
    list_contagiados_diarios = []
    for document in cursor:
        variables_globales = document['variablesGlobales']
        variable_dia = document['dia']
        
        if len(variables_globales) > 1:
            if variable_dia == 0:
                poblacion_actual = document['variablesSemilla']["poblacionInicial"]
                infeccioso_primer_dia = document['variablesSemilla']['infeccioso']
                list_contagiados_diarios.append(infeccioso_primer_dia)
            else:
                poblacion_actual = document['variablesCalculadas']["poblacionActual"]
            muertos_inicio = variables_globales[0]['inicio']['muertos']
            muertos_fin = variables_globales[1]['fin']['muertos']
            contagiados_inicio = variables_globales[0]['inicio']['contagiados']
            contagiados_fin = variables_globales[1]['fin']['contagiados']
            contagiados_por_dia = contagiados_fin - contagiados_inicio
            muertes_por_dia = muertos_fin - muertos_inicio

            if contagiados_por_dia == 0:
                list_contagiados_diarios.append(0)
            else:
                porcentaje = (contagiados_por_dia / poblacion_actual) * 100
                list_contagiados_diarios.append(porcentaje)

    #print("Lista:", list_contagiados_diarios)
    print("% contagiados:", sum(list_contagiados_diarios) / len(list_contagiados_diarios))
