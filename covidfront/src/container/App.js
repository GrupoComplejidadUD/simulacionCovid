import React from 'react';
import './App.css';
import GraphBar from "../components/GraphBar"
import Highcharts from 'highcharts/highstock'
import { Container } from 'semantic-ui-react'
import { Divider, Header, Icon, Image, Dimmer, Loader, Segment } from 'semantic-ui-react'
import StatisticFour from '../components/StatisticFour'

class App extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      awaitToRender: true,
      options: null,
      variablesGlobales: null
    };
  }

  async componentDidMount() {
    const apiURL = "http://127.0.0.1:5000/data";
    let response = await fetch(apiURL);
    let responseJson = await response.json();
    let MapOptions = {
      chart: {
        type: 'column'
      },
      title: {
        text: 'Numero de muertos - contagiados'
      },
      series: [],
      xAxis: {},
      yAxis: {
        min: 0,
        title: {
          text: 'Muertes'
        }
      }
    }

    let dataMuertos = [];
    let dataContagiados = [];
    let categorias = [];
    let promedioViajeIda = responseJson.promViajeIda.toFixed(2);
    let promedioViajeVuelta = responseJson.promViajeVuelta.toFixed(2);
    let totalMuertos = responseJson.muertesTotal;
    let totalContagiados = responseJson.contagiosTotal;
    for (const result of responseJson.result) {
      dataMuertos.push(result.muertos)
      dataContagiados.push(result.contagiados)
      categorias.push("dia " + result.dia)
    }

    MapOptions.series.push({ name: "Muertos", data: dataMuertos });
    MapOptions.series.push({ name: "Contagiados", data: dataContagiados });
    MapOptions.xAxis.categories = categorias;
    let variablesGlobales = {
      promMuertes : JSON.parse(responseJson.mean),
      promViajeIda : promedioViajeIda,
      promViajeVuelta : promedioViajeVuelta,
      totalMuertos : totalMuertos,
      totalContagiados : totalContagiados
    }
    this.setState({ options: MapOptions, awaitToRender: false, variablesGlobales : variablesGlobales})
  }


  render() {
    let awaitToRender = this.state.awaitToRender;

    return (
      <div>
        {awaitToRender ? (<div>
          <Segment>
            <Dimmer active>
              <Loader indeterminate>Preparando Graficas</Loader>
            </Dimmer>

            <Image src='https://react.semantic-ui.com/images/wireframe/short-paragraph.png' />
          </Segment>
        </div>
        ) :
          (

            <Container>
              <Header as='h2' icon textAlign='center'>
                <Icon name='users' circular />
                <Header.Content>Reporte Simulacion</Header.Content>
              </Header>
              <Divider />
              <GraphBar options={this.state.options} highcharts={Highcharts} />
              <StatisticFour variables={this.state.variablesGlobales}/>

            </Container>


          )}
      </div>
    );
  }

}

export default App;
