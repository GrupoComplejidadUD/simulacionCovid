import pymongo
from pymongo import MongoClient
import ast
import subprocess

dataBaseName = "SimulacionCovid"
dataBaseUrl = "localhost"
dataBasePort = 27017    
globalDict = {}


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
