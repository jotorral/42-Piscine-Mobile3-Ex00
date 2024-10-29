import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


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
  String selectedCity = '';
  String address = '';
  String temperature = '';
  String windSpeed = '';
  List<Map<String, String>> weatherToday = [];
  List<Map<String, String>> weatherWeekly = [];


  void _updateText(String text) async {
    useGPS = 0;
    showWeather = false;
    setState(() {});


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
      _getLocation();
    } else {
      // Si el permiso fue denegado, volver a pedir permiso
      PermissionStatus newPermission =
          await Permission.locationWhenInUse.request();
      if (newPermission.isGranted) {
        permissionGPS = 1;
        _getLocation();
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
      setState(() {
        locationMessage =
            'Lat: ${position.latitude}, Lon: ${position.longitude}';
        latitudeGPS = position.latitude;
        longitudeGPS = position.longitude;
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
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Padding(
            padding: EdgeInsets.only(
                right: 8.0), // Espacio entre la lupa y el TextField
            child: Icon(Icons.search,
                color: Color.fromARGB(255, 171, 171, 171)), // Ícono de la lupa
          ),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search location',
                hintStyle: TextStyle(color: Color.fromARGB(255, 171, 171, 171)),
                border: InputBorder.none,
                filled: true,
                fillColor: Color.fromARGB(255, 71, 92, 102),
              ),
              onChanged: _updateText,
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
              useGPS = 1;
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
                              : Text(address + weatherCurrently,
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center)),
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
                              : Column(
                                  children: [
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        color: Colors
                                            .black, // Texto en negro en los demás casos
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: weatherToday.length,
                                        itemBuilder: (context, index) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(weatherToday[index]
                                                      ['hour'] ??
                                                  ''),
                                              Text(
                                                  '${weatherToday[index]['temperature']}ºC'),
                                              Text(
                                                  '${weatherToday[index]['windspeed']} km/h'),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )),
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
                              : Column(
                                  children: [
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        color: Colors
                                            .black, // Texto en negro en los demás casos
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: weatherWeekly.length,
                                        itemBuilder: (context, index) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(weatherWeekly[index]
                                                      ['date'] ??
                                                  ''),
                                              Text(
                                                  '${weatherWeekly[index]['tempDayMin']}ºC'),
                                              Text(
                                                  '${weatherWeekly[index]['tempDayMax']}ºC'),
                                              Text(
                                                  '${weatherWeekly[index]['weatherDay']}'),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )),
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
    );
  }


/*  ListView  cityListWidget(){
    return  ListView.separated(
              itemCount: cityList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title:  Text(
                            cityList[index],
                            style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () {
                    showWeather = true;
                    finalCity = cityList[index];
                    getCoordinatesFromCityName(index);
                    },
                    );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                // Aquí defines la línea de separación
                  color: Colors.grey, // Color de la línea
                    thickness: 1.0, // Grosor de la línea},
                );
              });
  }
*/


int pageIndex = 0; // Página actual para controlar el índice de desplazamiento

Widget cityListWidget() {
  const int itemsPerPage = 5; // Número de elementos visibles por página

  // Cálculo de índices para la sublista de elementos visibles
  int startIndex = pageIndex * itemsPerPage;
  int endIndex = (startIndex + itemsPerPage).clamp(0, cityList.length); // Asegúrate de que endIndex no supere la longitud

  // Evitar que el índice de la página exceda el tamaño de la lista
  if (startIndex >= cityList.length) {
    // Asegúrate de que si estás al final no incrementes pageIndex
    pageIndex = (cityList.length / itemsPerPage).floor(); // Ajustar a la última página
    startIndex = pageIndex * itemsPerPage;
    endIndex = (startIndex + itemsPerPage).clamp(0, cityList.length);
  }

  List<String> visibleItems = cityList.sublist(startIndex, endIndex);

  return NotificationListener<ScrollNotification>(
    onNotification: (scrollInfo) {
      // Al llegar al final de la lista, aumenta el índice de página
      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent) {
        if (endIndex < cityList.length) {
          setState(() {
            pageIndex++;
          });
        }
      }
      // Al llegar al principio de la lista, disminuye el índice de página
      else if (scrollInfo.metrics.pixels <= scrollInfo.metrics.minScrollExtent) {
        if (pageIndex > 0) {
          setState(() {
            pageIndex--;
          });
        }
      }
      return true; // Retorna true para indicar que la notificación fue manejada
    },
    child: ListView.separated(
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            visibleItems[index],
            style: const TextStyle(fontSize: 10),
          ),
          onTap: () {
            // Acción al tocar el elemento
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


  void getCityNameFromCoordinates(
      double latitudeGPS, double longitudeGPS) async {
    final urlCity =
        'https://nominatim.openstreetmap.org/reverse?lat=$latitudeGPS&lon=$longitudeGPS&format=json';
//        'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$latitudeGPS&longitude=$longitudeGPS';
    final responseCity = await http.get(Uri.parse(urlCity));
    if (responseCity.statusCode == 200) {
      final dataCity = jsonDecode(responseCity.body);
      selectedCity = dataCity['address']['city'];
      address = dataCity['address']['city'] +
          '\n' +
          dataCity['address']['state'] +
          '\n' +
          dataCity['address']['country'];
      getWeatherFromCoordinates(latitudeGPS, longitudeGPS);
    }
  }


  void getCoordinatesFromCityName(index) async {
    final latit = cities[index]['latitude'];
    final longit = cities[index]['longitude'];


    try {
      selectedCity = cities[index]['name'];
      address = (selectedCity != '' ? '$selectedCity\n' : '') +
          (cities[index].containsKey('admin1') != ''
              ? '${cities[index]['admin1']}\n'
              : '') +
          (cities[index].containsKey('country') != ''
              ? '${cities[index]['country']}'
              : '');
    } catch (e) {
      temperature = 'Error';
      windSpeed = 'Error';
    }
    getWeatherFromCoordinates(latit, longit);
  }


// Método para obtener el clima desde Open Meteo
  void getWeatherFromCoordinates(double latit, double longit) async {
    final urlCurrently =
        'https://api.open-meteo.com/v1/forecast?latitude=$latit&longitude=$longit&current_weather=true&timezone=auto';


    try {
      final response = await http.get(Uri.parse(urlCurrently));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['current_weather']['temperature'].toString();
        final wind = data['current_weather']['windspeed'].toString();


        setState(() {
          temperature = temp;
          windSpeed = wind;
          weatherCurrently =
              (temperature != '\n' ? '\nTemperature: $temperatureºC\n' : '') +
                  (windSpeed != '' ? 'Wind Speed: $windSpeed km/h' : '');
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


    final urlToday =
        'https://api.open-meteo.com/v1/forecast?latitude=$latit&longitude=$longit&hourly=temperature_2m,windspeed_10m&timezone=auto';
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
          hourlyForecast.add({
            'hour': hour,
            'temperature': tempHour,
            'windspeed': windHour,
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



