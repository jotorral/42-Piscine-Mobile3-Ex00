import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide Position;
import 'package:intl/intl.dart';

List<dynamic> cities = [];
bool cityFound = true;
bool answerGeocoding = true;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Para quitar el banner de debug
      home: _HomePage(), // Hacer HomePage privada
    );
  }
}

// Ambas clases son privadas
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String searchText = ''; // Variable para guardar el texto ingresado
  String locationMessage = ''; // Variable con ubicación o mensaje de error
  int permissionGPS = 0; // Variable permiso de uso GPS
  int useGPS = 1; // Variable utilización del GPS
  List<String> cityList = []; // Lista de ciudades encontradas;
  bool showWeather = false; // Variable para mostrar el clima
  double latitudeGPS = 0.0; // Latitud GPS
  double longitudeGPS = 0.0; // Longitud GPS
  String finalCity = ''; // Variable para guardar la ciudad final = '';
  String weatherCurrently = '';
  String weatherCurrentlyCode = '';
  String environementCurrently = '';
  String windSpeedCurrently = '';
  String selectedCity = '';
  String selectedAdmin = '';
  String selectedAdmin1 = '';
  String selectedCountry = '';
  String address = '';
  String commaSpace = ', ';
  String centigrades = 'ºC';
  String temperature = '';
  String windSpeed = '';
  List<Map<String, String>> weatherToday = [];
  List<Map<String, String>> weatherWeekly = [];

  void updateText(String text) async {
    useGPS = 0;
    showWeather = false;
    setState(() {});
    pageIndex = 0;

    GeocodingService geoService = GeocodingService();
    try {
      cityList = await geoService.getCityList(text);
      if (cityList.isNotEmpty) {
        setState(() {
          searchText = cityList[0];
        });
      } else {
        setState(() {});
      }
    } catch (e) {
//      print(e); // Manejo de errores
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _checkLocationPermission(); // Verifica los permisos al iniciar la app
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método para verificar el permiso de ubicación
  Future<void> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.locationWhenInUse.status;

    if (permission.isGranted) {
      // Si el permiso fue concedido, obtener la ubicación
      permissionGPS = 1;
      await _getLocation();
    } else {
      // Si el permiso fue denegado, volver a pedir permiso
      PermissionStatus newPermission =
          await Permission.locationWhenInUse.request();
      if (newPermission.isGranted) {
        permissionGPS = 1;
        await _getLocation();
      } else {
        // El usuario denegó el permiso
        setState(() {
          permissionGPS = 0;
          locationMessage = (useGPS == 0)
              ? "Using search input: $searchText"
              : "Geolocation is not available, please enable it in your App settings";
        });
      }
    }
  }

  // Método para obtener la ubicación del dispositivo
  Future<void> _getLocation() async {
    try {
      // Configuración de ubicación
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Cambia esto según lo que necesites
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      debugPrint('******Latitude*****');
      debugPrint(position.latitude.toString());
      debugPrint('\n');
      debugPrint('******Longitude*****');
      debugPrint(position.longitude.toString());
      debugPrint('\n');

      setState(() {
        locationMessage =
            'Lat: ${position.latitude}, Lon: ${position.longitude}';
        latitudeGPS = position.latitude;
        longitudeGPS = position.longitude;
//        latitudeGPS = 43.37994;
//        longitudeGPS = -2.96029;
//        latitudeGPS = 42.34711875194457; // EN EL MEDIO DEL MAR
//        longitudeGPS = -40.13449900094774; // EN EL MEDIO DEL MAR
//          latitudeGPS = 40.761430;
//          longitudeGPS = 73.977620;

        getCityNameFromCoordinates(latitudeGPS, longitudeGPS);
        showWeather = true;
      });
    } catch (e) {
      setState(() {
        locationMessage = 'Error getting location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/weather_background1.jpg'),
          fit: BoxFit.cover,
        ),
				color: Colors.blue.withOpacity(0.1),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(children: [
            const Padding(
              padding: EdgeInsets.only(
                  right: 8.0), // Espacio entre la lupa y el TextField
              child: Icon(Icons.search,
                  color:
                      Color.fromARGB(255, 171, 171, 171)), // Ícono de la lupa
            ),
            Expanded(
              child: TextField(
//                controller: TextEditingController(text:),
                decoration: const InputDecoration(
                  hintText: 'Search location',
                  hintStyle:
                      TextStyle(color: Color.fromARGB(255, 171, 171, 171)),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Color.fromARGB(255, 71, 92, 102),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged:
                    updateText, // Pasa el parámetro TextField convertido a string a updateText
              ),
            ),
            IconButton(
              icon: Transform.rotate(
                angle: 0.7,
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                // Cuando se presiona el botón de geolocalización
                _checkLocationPermission();
              },
            ),
          ]),
          backgroundColor: const Color.fromARGB(255, 71, 92, 102),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Center(
                // CURRENTLY
                child: cityFound == false
                    ? const Text(
                        'Could not find any result for the supplied address or coordinates.',
                        style: TextStyle(fontSize: 24, color: Colors.red),
                        textAlign: TextAlign.center)
                    : answerGeocoding == false
                        ? const Text(
                            'The service connection is lost, please check your internet connection or try again later.',
                            style: TextStyle(fontSize: 24, color: Colors.red),
                            textAlign: TextAlign.center)
                        : permissionGPS == 0 && useGPS == 1
                            ? Text(
                                'Currently\n $locationMessage',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors
                                      .red, // Texto en negro en los demás casos
                                ),
                                textAlign: TextAlign.center,
                              )
                            : showWeather == false
                                ? cityListWidget()
                                : currentlyWeatherWidget()),
            Center(
                // TODAY
                child: cityFound == false
                    ? const Text('City not Found',
                        style: TextStyle(fontSize: 24, color: Colors.red),
                        textAlign: TextAlign.center)
                    : answerGeocoding == false
                        ? const Text('Geocoding Widget did not answer',
                            style: TextStyle(fontSize: 24, color: Colors.red),
                            textAlign: TextAlign.center)
                        : permissionGPS == 0 && useGPS == 1
                            ? const Text(
                                'Today\nGeolocation is not available, please enable it in your App settings',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : showWeather == false
                                ? cityListWidget()
                                : todayWeatherWidget()),
            Center(
                // WEEKLY
                child: cityFound == false
                    ? const Text('City not Found',
                        style: TextStyle(fontSize: 24, color: Colors.red),
                        textAlign: TextAlign.center)
                    : answerGeocoding == false
                        ? const Text('Geocoding Widget did not answer',
                            style: TextStyle(fontSize: 24, color: Colors.red),
                            textAlign: TextAlign.center)
                        : permissionGPS == 0 && useGPS == 1
                            ? const Text(
                                'Weekly\nGeolocation is not available, please enable it in your App settings',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : showWeather == false
                                ? cityListWidget()
                                : weeklyWeatherWidget()),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.settings), text: 'Currently'),
              Tab(icon: Icon(Icons.today), text: 'Today'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Weekly'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget currentlyWeatherWidget() {
    return Column(children: [
      const SizedBox(height: 10.0),
      Text(
          selectedCity/* +
              commaSpace +
              latitudeGPS.toString() +
              commaSpace +
              longitudeGPS.toString() + selectedAdmin*/,
          style: const TextStyle(
              fontSize: 14, color: Color.fromRGBO(126, 229, 255, 1))),
      Text(
        selectedAdmin1 +
            commaSpace +
            selectedCountry /* +
						latitudeGPS.toString() +
						longitudeGPS.toString()*/
        ,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
      const Text('', style: TextStyle(fontSize: 40)),
      Text(temperature + centigrades,
          style: const TextStyle(
              fontSize: 32, color: Color.fromARGB(255, 255, 226, 78))),
      const Text('', style: TextStyle(fontSize: 25)),
      Text(environementCurrently,
          style: const TextStyle(fontSize: 16, color: Colors.white)),
      weatherIcon(weatherCurrentlyCode),
      const Text('', style: TextStyle(fontSize: 25)),
      Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              WeatherIcons.strong_wind, // Ícono de viento fuerte
              size: 30.0, // Puedes ajustar el tamaño
              color: Colors.blue, // Cambia el color si lo deseas
            ),
            const SizedBox(width: 10.0),
            Text(windSpeedCurrently,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            const Text(' km/h',
                style: TextStyle(fontSize: 14, color: Colors.white))
          ]),
    ]);
  }

  Widget todayWeatherWidget() {
    // Convertimos los datos de `weatherToday` a una lista que el gráfico pueda procesar
    final List<Map<String, dynamic>> chartData = weatherToday.map((data) {
      return {
        'hour': data[
            'hour'], // Mantenemos la hora como String para mostrar en el gráfico
        'temperature': double.tryParse(data['temperature'].toString()) ?? 0.0,
      };
    }).toList();

    return Column(
      children: [
        Text(selectedCity /* + commaSpace + selectedAdmin*/,
            style: const TextStyle(
                fontSize: 14, color: Color.fromRGBO(126, 229, 255, 1))),
        Text(
          selectedAdmin1 +
              commaSpace +
              selectedCountry /* +
							latitudeGPS.toString() +
							longitudeGPS.toString()*/
          ,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        Expanded(
          child: SfCartesianChart(
            primaryXAxis: const CategoryAxis(
//            title: AxisTitle(text: 'Hora'),
              labelStyle: TextStyle(color: Colors.yellow),
            ),
            primaryYAxis: const NumericAxis(
//            title: AxisTitle(text: 'Temperatura (ºC)'),
              labelFormat: '{value}ºC',
              labelStyle: TextStyle(color: Colors.yellow),
            ),
            series: <CartesianSeries<Map<String, dynamic>, String>>[
              LineSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data['hour'].toString(),
                  yValueMapper: (data, _) => data['temperature'],
                  name: 'Temperatura',
                  color: Colors.orange,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.greenAccent),
                  ),
                  markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: Colors.orange,
                      borderColor: Colors.white,
                      height: 5,
                      width: 5)),
            ],
          ),
        ),
        const Divider(
          color: Colors.grey, // Color de la línea divisoria
          thickness: 2, // Grosor de la línea
        ),
        SizedBox(
          height: 110, // Ajusta la altura según lo necesites
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weatherToday.length,
            itemBuilder: (context, index) {
              return Container(
                width: 100, // Ancho de cada columna
                margin: const EdgeInsets.all(4.0), // Espacio entre columnas
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(weatherToday[index]['hour'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.amberAccent)),
                    weatherIcon(weatherToday[index]['weathercode']
                        .toString()), // Icono del clima
                    Text(
                      '${weatherToday[index]['temperature']}ºC',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent),
                    ), // Temperatura
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          WeatherIcons.strong_wind, // Ícono de viento fuerte
                          size: 20.0, // Puedes ajustar el tamaño
                          color: Colors
                              .lightBlueAccent, // Cambia el color si lo deseas
                        ),
                        const SizedBox(width: 6), // Espacio entre icono y texto
                        Text('${weatherToday[index]['windspeed']} km/h',
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.tealAccent)), // Velocidad del viento
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget weeklyWeatherWidget() {
    final List<Map<String, dynamic>> chartData = weatherWeekly.map((data) {
      return {
        'date': data[
            'date'], // Mantenemos la fecha como String para mostrar en el gráfico
        'tempDayMax': double.tryParse(data['tempDayMax'].toString()) ?? 0.0,
        'tempDayMin': double.tryParse(data['tempDayMin'].toString()) ?? 0.0,
      };
    }).toList();
    return (Column(
      children: [
        Text(selectedCity /* + commaSpace + selectedAdmin*/,
            style: const TextStyle(
                fontSize: 14, color: Color.fromRGBO(126, 229, 255, 1))),
        Text(
          selectedAdmin1 +
              commaSpace +
              selectedCountry /* +
							latitudeGPS.toString() +
							longitudeGPS.toString()*/
          ,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        Expanded(
          child: SfCartesianChart(
            primaryXAxis: const CategoryAxis(
//            title: AxisTitle(text: 'Hora'),
              labelStyle: TextStyle(color: Colors.yellow),
            ),
            primaryYAxis: const NumericAxis(
//            title: AxisTitle(text: 'Temperatura (ºC)'),
              labelFormat: '{value}ºC',
              labelStyle: TextStyle(color: Colors.yellow),
            ),
            series: <CartesianSeries<Map<String, dynamic>, String>>[
              LineSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) =>
                      formatToDDMM(data['date'].toString()),
                  yValueMapper: (data, _) => data['tempDayMax'],
                  name: 'Temperatura Max',
                  color: Colors.red,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.greenAccent),
                  ),
                  markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: Colors.red,
                      borderColor: Colors.white,
                      height: 5,
                      width: 5)),
              LineSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) =>
                      formatToDDMM(data['date'].toString()),
                  yValueMapper: (data, _) => data['tempDayMin'],
                  name: 'Temperatura Min',
                  color: Colors.lightBlue,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.greenAccent),
                  ),
                  markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: Colors.lightBlue,
                      borderColor: Colors.white,
                      height: 5,
                      width: 5)),
            ],
          ),
        ),
        const Divider(
          color: Colors.grey, // Color de la línea divisoria
          thickness: 2, // Grosor de la línea
        ),
        SizedBox(
          height: 110, // Ajusta la altura según lo necesites
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weatherWeekly.length,
            itemBuilder: (context, index) {
              return Container(
                width: 100, // Ancho de cada columna
                margin: const EdgeInsets.all(4.0), // Espacio entre columnas
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(formatToDDMM(weatherWeekly[index]['date'] ?? ''),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.amberAccent)),
                    weatherIcon(weatherWeekly[index]['weathercode']
                        .toString()), // Icono del clima
                    Text(
                      '${weatherWeekly[index]['tempDayMax']}ºC max',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent),
                    ), // Temperatura
                    Text(
                      '${weatherWeekly[index]['tempDayMin']}ºC min',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromRGBO(126, 229, 255, 1)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  int pageIndex = 0; // Página actual para controlar el índice de desplazamiento

  Widget cityListWidget() {
    const int itemsPerPage = 5; // Número de elementos visibles por página

    // Limitar startIndex y endIndex dentro del rango
    int startIndex = (pageIndex * itemsPerPage).clamp(0, cityList.length);
    int endIndex = (startIndex + itemsPerPage).clamp(0, cityList.length);

    // Crear sublista de elementos visibles
    List<String> visibleItems = cityList.sublist(startIndex, endIndex);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification) {
          // Al llegar al final de la lista, incrementa el índice de página si no estamos en la última página
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent &&
              endIndex < cityList.length) {
            setState(() {
              pageIndex++;
            });
          } else if (scrollInfo.metrics.pixels <=
                  scrollInfo.metrics.minScrollExtent &&
              pageIndex > 0) {
            // Al llegar al inicio de la lista, decrementa el índice de página si no estamos en la primera página
            setState(() {
              pageIndex--;
            });
          }
        }
        return true; // Indica que la notificación fue manejada
      },
      child: ListView.separated(
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          debugPrint('Visible Item: ${visibleItems[index]}');

          // Divide el nombre en partes, reemplazando "null" con ""
          List<String> nameParts = visibleItems[index]
              .split(',')
              .map((part) => part.trim() == "null" ? "" : part.trim())
              .toList();

          return ListTile(
            title: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 10, color: Color.fromARGB(255, 143, 142, 142)),
                children: [
                  TextSpan(
                    text: nameParts[0], // Primer nombre (o vacío si es "null")
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 217, 0)),
                  ),
                  if (nameParts.length > 1)
                    const TextSpan(
                      text: ' ',
                    ),
                  if (nameParts.length > 1)
                    TextSpan(
                      text:
                          nameParts.sublist(1).join(', '), // Nombres restantes
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ),
            onTap: () {
//              updateText('');
              showWeather = true;
              finalCity = visibleItems[index];
              getCoordinatesFromCityName(startIndex + index);
            },
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(
            color: Colors.grey,
            thickness: 1.0,
          );
        },
      ),
    );
  }

  Future<void> getCityNameFromCoordinates(
      double latitudeGPS, double longitudeGPS) async {
//    String latitudeGPS1 = latitudeGPS.toString();
//    String longitudeGPS1 = longitudeGPS.toString();
    selectedCity = '';
//    selectedAdmin = '';
    selectedAdmin1 = '';
    selectedCountry = '';

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitudeGPS, longitudeGPS);
      Placemark? firstValidPlacemark;
    for (var placemark in placemarks) {
			if (placemark.locality != null && placemark.locality != '' &&
					placemark.administrativeArea != null && placemark.administrativeArea != '' &&
					placemark.country != null && placemark.country != '') {
				firstValidPlacemark = placemark;
				break; // Salir del bucle en cuanto encontremos el primer placemark válido
			}
		}
//      firstValidPlacemark = null;
      if (firstValidPlacemark != null) {
        // Si encontramos un placemark válido, puedes acceder a los valores
        selectedCity = firstValidPlacemark.locality ?? '';
        selectedAdmin1 = firstValidPlacemark.administrativeArea ?? '';
        selectedCountry = firstValidPlacemark.country ?? '';
        selectedAdmin = firstValidPlacemark.subAdministrativeArea ?? '';
      } else {
        // Recorre los placemarks para obtener el primer valor no nulo de cada campo
        for (var placemark in placemarks) {
          if (selectedCity.isEmpty && placemark.locality != null && placemark.locality != '') {
            selectedCity = placemark.locality!;
          }
          if (selectedAdmin1.isEmpty && placemark.administrativeArea != null && placemark.administrativeArea != '') {
            selectedAdmin1 = placemark.administrativeArea!;
          }
          if (selectedCountry.isEmpty && placemark.country != null && placemark.country != '') {
            selectedCountry = placemark.country!;
          }

          // Salir del bucle si todos los campos ya tienen un valor
          if (selectedCity.isNotEmpty &&
              selectedAdmin1.isNotEmpty &&
              selectedCountry.isNotEmpty) {
            break;
          }
        }
      }
    } catch (e) {
      selectedCity = 'CITY NOT';
      selectedAdmin1 = 'FOUND HERE';
      selectedCountry = '';
    }
    await getWeatherFromCoordinates(latitudeGPS, longitudeGPS);

/*
		final urlCity =
				'https://nominatim.openstreetmap.org/reverse?lat=$latitudeGPS1&lon=$longitudeGPS1&format=json';
//        'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$latitudeGPS1&longitude=$longitudeGPS1';

		final headers = {
			'Accept': 'application/json',
			'User-Agent': 'MyApp/1.138',
			'Connection': 'Keep-Alive',
		};

		final http.Response responseCity =
				await http.get(Uri.parse(urlCity), headers: headers);

		debugPrint(
				'*************** City found3 ************** ${responseCity.statusCode.toString()}\n');
		if (responseCity.statusCode == 200) {
			final dataCity = jsonDecode(responseCity.body);
			selectedCity = dataCity['address']['city'];
			selectedAdmin1 = dataCity['address']['state'];
			selectedCountry = dataCity['address']['country'];
			address = dataCity['address']['city'] +
					'\n' +
					dataCity['address']['state'] +
					'\n' +
					dataCity['address']['country'];

			await getWeatherFromCoordinates(latitudeGPS, longitudeGPS);
		} else {
			await getWeatherFromCoordinates(latitudeGPS, longitudeGPS);
			setState(() {});
		}
		*/
  }

  Future<void> getCoordinatesFromCityName(index) async {
    final latit = cities[index]['latitude'];
    final longit = cities[index]['longitude'];

    try {
      setState(() {
        selectedCity = cities[index]['name'];
//        selectedAdmin = cities[index]['admin2'];
        selectedAdmin1 = cities[index]['admin1'];
        selectedCountry = cities[index]['country'];
        address = (selectedCity != '' ? '$selectedCity\n' : '') +
            (cities[index].containsKey('admin1') != ''
                ? '${cities[index]['admin1']}\n'
                : '') +
            (cities[index].containsKey('admin2') != ''
                ? '${cities[index]['admin2']}\n'
                : '') +
            (cities[index].containsKey('country') != ''
                ? '${cities[index]['country']}'
                : '');
      });
    } catch (e) {
      temperature = 'Error';
      windSpeed = 'Error';
      windSpeedCurrently = 'Error';
    }
    getWeatherFromCoordinates(latit, longit);
  }

// Método para obtener el clima desde Open Meteo
  Future<void> getWeatherFromCoordinates(double latit, double longit) async {
    final urlCurrently =
        'https://api.open-meteo.com/v1/forecast?latitude=$latit&longitude=$longit&current_weather=true&timezone=auto';

    try {
      final response = await http.get(Uri.parse(urlCurrently));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['current_weather']['temperature'].toString();
        final wind = data['current_weather']['windspeed'].toString();
        final weatherCode = data['current_weather']['weathercode'].toString();
        environementCurrently = weatherCodeToWord(weatherCode);
        weatherCurrentlyCode = weatherCode;

        setState(() {
          Future.delayed(const Duration(milliseconds: 10), () {
            temperature = temp;
            windSpeedCurrently = wind;
            weatherCurrently =
                (temperature != '\n' ? '\nTemperature: $temperatureºC\n' : '') +
                    (windSpeedCurrently != ''
                        ? 'Wind Speed: $windSpeedCurrently km/h'
                        : '');
          });
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        temperature = 'Error';
        windSpeedCurrently = 'Error';
      });
    }

    final urlToday =
        'https://api.open-meteo.com/v1/forecast?latitude=$latit&longitude=$longit&hourly=temperature_2m,windspeed_10m,weathercode&timezone=auto';
    try {
      final response =
          await http.get(Uri.parse(urlToday)); // http.Response response = ...

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body); // Map<String, dynamic> data = ...

        // Construir las columnas de pronóstico horario
        List<Map<String, String>> hourlyForecast = [];
        for (int i = 0; i < 24; i++) {
          String hour = data['hourly']['time'][i]
              .substring(11, 16); // Obtener hora (formato HH:mm)
          String tempHour = data['hourly']['temperature_2m'][i].toString();
          String windHour = data['hourly']['windspeed_10m'][i].toString();
          String weatherCodeHour = data['hourly']['weathercode'][i].toString();
          hourlyForecast.add({
            'hour': hour,
            'temperature': tempHour,
            'windspeed': windHour,
            'weathercode': weatherCodeHour,
          });
        }
        setState(() {
          // Asignamos el pronóstico horario a weatherToday
          weatherToday = hourlyForecast;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        temperature = 'Error';
        windSpeed = 'Error';
      });
    }

    final urlWeekly =
        'https://api.open-meteo.com/v1/forecast?latitude=$latit&longitude=$longit&daily=temperature_2m_min,temperature_2m_max,weathercode&timezone=auto';
    try {
      final response =
          await http.get(Uri.parse(urlWeekly)); // http.Response response = ...

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body); // Map<String, dynamic> data = ...

        // Construir las columnas de pronóstico horario
        List<Map<String, String>> weeklyForecast = [];
        for (int i = 0; i < 7; i++) {
          String date = data['daily']['time'][i];
          String tempDayMin = data['daily']['temperature_2m_min'][i].toString();
          String tempDayMax = data['daily']['temperature_2m_max'][i].toString();
          String weatherCode = data['daily']['weathercode'][i].toString();
          String weatherDay = weatherCodeToWord(weatherCode);
          weeklyForecast.add({
            'date': date,
            'tempDayMin': tempDayMin,
            'tempDayMax': tempDayMax,
            'weatherDay': weatherDay,
            'weathercode': weatherCode,
          });
        }
        setState(() {
          // Asignamos el pronóstico horario a weatherToday
          weatherWeekly = weeklyForecast;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        weatherWeekly = [];
      });
    }
  }
}

class GeocodingService {
  // Método para obtener una lista de ciudades y sus datos a partir del nombre de una ciudad
  Future<List<String>> getCityList(String cityName) async {
    final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&language=en'); // language = es
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint(
          '*************** GeocodingService ha respondido **************\n');
      final data = json.decode(response.body);
      debugPrint(
          '*************** Respuesta API: $data **************\n'); // Imprimir la respuesta completa

      if (data.containsKey('results') &&
          data['results'] != null &&
          data['results'].isNotEmpty) {
        // Generamos la lista de resultados con el nombre, país, región, comarca, etc.
        cities = data['results'];
        debugPrint('*************** City found1 **************\n');
        List<String> searchResults = cities
            .map((city) =>
                '${city['name']}, ${city['admin1']}, ${city['country']}')
            .toList();
        debugPrint('*************** City found2 **************\n');
        cityFound = true;
        answerGeocoding = true;
        return searchResults; // Devolvemos la lista
      } else {
        debugPrint('*************** No city found **************\n');
        cityFound = false;
        return [];
      }
    } else {
      debugPrint('GeocodingService does not answer\n');
      answerGeocoding = false;
      return [];
    }
  }
}

String weatherCodeToWord(String weatherCode) {
  final weatherDescriptions = {
    // final Map<String, String> weatherDescriptions
    '0': 'Clear sky',
    '1': 'Mainly clear',
    '2': 'Partly cloudy',
    '3': 'Overcast',
    '45': 'Fog',
    '48': 'Depositing rime fog',
    '51': 'Drizzle: Light intensity',
    '53': 'Drizzle: Moderate intensity',
    '55': 'Drizzle: Dense intensity',
    '56': 'Freezing Drizzle: Light intensity',
    '57': 'Freezing Drizzle: Dense intensity',
    '61': 'Rain: Slight intensity',
    '63': 'Rain: Moderate intensity',
    '65': 'Rain: Heavy intensity',
    '66': 'Freezing Rain: Light intensity',
    '67': 'Freezing Rain: Heavy intensity',
    '71': 'Snow fall: Slight intensity',
    '73': 'Snow fall: Moderate intensity',
    '75': 'Snow fall: Heavy intensity',
    '77': 'Snow grains',
    '80': 'Rain showers: Slight',
    '81': 'Rain showers: Moderate',
    '82': 'Rain showers: Violent',
    '85': 'Snow showers: Slight',
    '86': 'Snow showers: Heavy',
    '95': 'Thunderstorm: Slight or moderate',
    '96': 'Thunderstorm with slight hail',
    '99': 'Thunderstorm with heavy hail',
  };
  // Busca el código en el mapa
  return weatherDescriptions[weatherCode] ?? 'Unknown weather code';
}

Widget weatherIcon(String weatherCode) {
  // Mapa de íconos de clima
  final Map<String, IconData> weatherIcons = {
    '0': Icons.wb_sunny,
    '1': Icons.wb_sunny,
    '2': Icons.cloud,
    '3': Icons.cloud_done,
    '45': Icons.foggy,
    '48': Icons.foggy,
    '51': Icons.grain,
    '53': Icons.grain,
    '55': Icons.grain,
    '56': Icons.snowing,
    '57': Icons.snowing,
    '61': Icons.umbrella,
    '63': Icons.umbrella,
    '65': Icons.umbrella,
    '66': Icons.umbrella,
    '67': Icons.umbrella,
    '71': Icons.ac_unit,
    '73': Icons.ac_unit,
    '75': Icons.ac_unit,
    '77': Icons.ac_unit,
    '80': Icons.umbrella,
    '81': Icons.umbrella,
    '82': Icons.umbrella,
    '85': Icons.ac_unit,
    '86': Icons.ac_unit,
    '95': Icons.thunderstorm,
    '96': Icons.thunderstorm,
    '99': Icons.thunderstorm,
  };

  // Obtiene el ícono
  IconData icon = weatherIcons[weatherCode] ?? Icons.help; // Ícono por defecto

  return Icon(icon, size: 40, color: Colors.lightBlueAccent);
}

String formatToDDMM(String dateString) {
  DateTime date = DateTime.parse(dateString);
  return DateFormat('dd/MM').format(date);
}
