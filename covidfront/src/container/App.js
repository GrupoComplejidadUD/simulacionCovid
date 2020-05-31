import React from 'react';
import './App.css';
import GraphBar from "../components/GraphBar"
import Highcharts from 'highcharts/highstock'
import { Container } from 'semantic-ui-react'
import { Divider, Header, Icon, Image, Dimmer, Loader, Segment, Grid } from 'semantic-ui-react'
import StatisticFour from '../components/StatisticFour'
import StatisticContagio from '../components/StatisticContagio'
import StatisticHead from '../components/StatisticHead'

class App extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      awaitToRender: true,
      options: null,
      options2: null,
      options3: null,
      variablesGlobales: null,
      lugaresContagio: null
    };
  }

  createOptions(type, title, textYAxis) {
    let options = {
      chart: {
        type: type
      },
      title: {
        text: title
      },
      series: [],
      xAxis: {},
      yAxis: {
        min: 0,
        title: {
          text: textYAxis
        }
      }
    }
    return options;
  }

  async componentDidMount() {
    const apiURL = "http://127.0.0.1:5000/data";
    let response = await fetch(apiURL);
    let responseJson = await response.json();
    let MapOptions = this.createOptions('column', 'Numero de muertos - contagiados', 'Muertes')

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

    console.log(categorias)
    MapOptions.series.push({ name: "Muertos", data: dataMuertos });
    MapOptions.series.push({ name: "Contagiados", data: dataContagiados });
    MapOptions.xAxis.categories = categorias;
    
    let variablesGlobales = {
      promMuertes: JSON.parse(responseJson.mean),
      promViajeIda: promedioViajeIda,
      promViajeVuelta: promedioViajeVuelta,
      totalMuertos: totalMuertos,
      totalContagiados: totalContagiados
    }

    console.log(variablesGlobales)

    let MapOptions2 = this.createOptions('column', 'Lugares de contagio', 'Contagios')
    let lugaresContagio = responseJson.lugaresContagio;
    MapOptions2.series.push({ name: "Trabajo", data: [lugaresContagio.trabajo] })
    MapOptions2.series.push({ name: "Casa", data: [lugaresContagio.casa] })
    MapOptions2.series.push({ name: "Sin definir", data: [lugaresContagio["sin definir"]] })
    MapOptions2.series.push({ name: "Transporte", data: [lugaresContagio.transporte] })


    let MapOptions3 = this.createOptions('column', 'Contagios por estrato', 'Contagios')
    let estratosContagio = responseJson.estratoSocioeconomico;
    MapOptions3.series.push({ name: "Estrato 1", data: [estratosContagio["1"]] })
    MapOptions3.series.push({ name: "Estrato 2", data: [estratosContagio["2"]] })
    MapOptions3.series.push({ name: "Estrato 3", data: [estratosContagio["3"]] })
    MapOptions3.series.push({ name: "Estrato 4", data: [estratosContagio["4"]] })
    MapOptions3.series.push({ name: "Estrato 5", data: [estratosContagio["5"]] })
    MapOptions3.series.push({ name: "Estrato 6", data: [estratosContagio["6"]] })


    this.setState({ 
      options: MapOptions, 
      options2: MapOptions2, 
      options3: MapOptions3,
      awaitToRender: false, 
      variablesGlobales: variablesGlobales, 
      lugaresContagio: lugaresContagio 
    })
  }


  render() {
    let awaitToRender = this.state.awaitToRender;

    return (
      <div>
        {awaitToRender ? (<div>

          <Container>
            <Grid>
              <Grid.Row centered>
                <Segment>
                  <Dimmer active>
                    <Loader indeterminate>Preparando Graficas</Loader>
                  </Dimmer>
                  <Image src='https://react.semantic-ui.com/images/wireframe/short-paragraph.png' />
                </Segment>
              </Grid.Row>
            </Grid>
          </Container>

        </div>
        ) :
          (

            <Container>
              <Segment>
              <StatisticHead></StatisticHead>
                <Header as='h2' icon textAlign='center'>
                  <Icon name='users' circular />
                  <Header.Content>Reporte Muertes y contagios</Header.Content>
                </Header>
                <Divider section />
                <GraphBar options={this.state.options} highcharts={Highcharts} />
                <StatisticFour variables={this.state.variablesGlobales} />
                <Divider section />
                <Header as='h2' icon textAlign='center'>
                  <Icon name='home' circular />
                  <Header.Content>Reporte Lugares de Contagio</Header.Content>
                </Header>
                <GraphBar options={this.state.options2} highcharts={Highcharts} />
                <StatisticContagio variables={this.state.lugaresContagio} />

                <Divider section />
                <Header as='h2' icon textAlign='center'>
                  <Icon name='home' circular />
                  <Header.Content>Reporte Contagios Estrato</Header.Content>
                </Header>
                <GraphBar options={this.state.options3} highcharts={Highcharts} />

              </Segment>
            </Container>

          )}
      </div>
    );
  }

}

export default App;
