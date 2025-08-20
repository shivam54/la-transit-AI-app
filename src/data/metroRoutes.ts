import { MetroRoute, Station } from '../types';

export const metroStations: Station[] = [
  // Red Line Stations
  {
    id: 'red-union-station',
    name: 'Union Station',
    latitude: 34.0556,
    longitude: -118.2344,
    lines: ['red'],
    address: '800 N Alameda St, Los Angeles, CA 90012',
    facilities: ['parking', 'bike_racks', 'restrooms']
  },
  {
    id: 'red-civic-center',
    name: 'Civic Center/Grand Park',
    latitude: 34.0550,
    longitude: -118.2430,
    lines: ['red'],
    address: '101 S Hill St, Los Angeles, CA 90012'
  },
  {
    id: 'red-pershing-square',
    name: 'Pershing Square',
    latitude: 34.0490,
    longitude: -118.2500,
    lines: ['red'],
    address: '532 S Olive St, Los Angeles, CA 90013'
  },
  {
    id: 'red-7th-street',
    name: '7th Street/Metro Center',
    latitude: 34.0470,
    longitude: -118.2580,
    lines: ['red', 'purple', 'blue', 'expo'],
    address: '700 S Flower St, Los Angeles, CA 90017'
  },
  {
    id: 'red-westlake',
    name: 'Westlake/MacArthur Park',
    latitude: 34.0570,
    longitude: -118.2750,
    lines: ['red'],
    address: '660 S Westlake Ave, Los Angeles, CA 90057'
  },
  {
    id: 'red-wilshire-vermont',
    name: 'Wilshire/Vermont',
    latitude: 34.0620,
    longitude: -118.2910,
    lines: ['red'],
    address: '3010 Wilshire Blvd, Los Angeles, CA 90010'
  },
  {
    id: 'red-wilshire-western',
    name: 'Wilshire/Western',
    latitude: 34.0620,
    longitude: -118.3080,
    lines: ['red'],
    address: '3775 Wilshire Blvd, Los Angeles, CA 90010'
  },
  {
    id: 'red-vermont-sunset',
    name: 'Vermont/Sunset',
    latitude: 34.0980,
    longitude: -118.2910,
    lines: ['red'],
    address: '1500 N Vermont Ave, Los Angeles, CA 90027'
  },
  {
    id: 'red-vermont-santa-monica',
    name: 'Vermont/Santa Monica',
    latitude: 34.0890,
    longitude: -118.2910,
    lines: ['red'],
    address: '1400 N Vermont Ave, Los Angeles, CA 90027'
  },
  {
    id: 'red-hollywood-western',
    name: 'Hollywood/Western',
    latitude: 34.1020,
    longitude: -118.3080,
    lines: ['red'],
    address: '5450 Hollywood Blvd, Los Angeles, CA 90027'
  },
  {
    id: 'red-hollywood-vine',
    name: 'Hollywood/Vine',
    latitude: 34.1020,
    longitude: -118.3250,
    lines: ['red'],
    address: '6250 Hollywood Blvd, Los Angeles, CA 90028'
  },
  {
    id: 'red-hollywood-highland',
    name: 'Hollywood/Highland',
    latitude: 34.1020,
    longitude: -118.3390,
    lines: ['red'],
    address: '6801 Hollywood Blvd, Los Angeles, CA 90028'
  },
  {
    id: 'red-universal-city',
    name: 'Universal City/Studio City',
    latitude: 34.1380,
    longitude: -118.3590,
    lines: ['red'],
    address: '3900 Lankershim Blvd, Universal City, CA 91608'
  },
  {
    id: 'red-north-hollywood',
    name: 'North Hollywood',
    latitude: 34.1680,
    longitude: -118.3770,
    lines: ['red'],
    address: '5250 Lankershim Blvd, North Hollywood, CA 91601'
  },

  // Purple Line Stations
  {
    id: 'purple-union-station',
    name: 'Union Station',
    latitude: 34.0556,
    longitude: -118.2344,
    lines: ['purple'],
    address: '800 N Alameda St, Los Angeles, CA 90012'
  },
  {
    id: 'purple-civic-center',
    name: 'Civic Center/Grand Park',
    latitude: 34.0550,
    longitude: -118.2430,
    lines: ['purple'],
    address: '101 S Hill St, Los Angeles, CA 90012'
  },
  {
    id: 'purple-pershing-square',
    name: 'Pershing Square',
    latitude: 34.0490,
    longitude: -118.2500,
    lines: ['purple'],
    address: '532 S Olive St, Los Angeles, CA 90013'
  },
  {
    id: 'purple-7th-street',
    name: '7th Street/Metro Center',
    latitude: 34.0470,
    longitude: -118.2580,
    lines: ['purple'],
    address: '700 S Flower St, Los Angeles, CA 90017'
  },
  {
    id: 'purple-wilshire-western',
    name: 'Wilshire/Western',
    latitude: 34.0620,
    longitude: -118.3080,
    lines: ['purple'],
    address: '3775 Wilshire Blvd, Los Angeles, CA 90010'
  },
  {
    id: 'purple-wilshire-normandie',
    name: 'Wilshire/Normandie',
    latitude: 34.0620,
    longitude: -118.3250,
    lines: ['purple'],
    address: '3500 Wilshire Blvd, Los Angeles, CA 90010'
  },
  {
    id: 'purple-wilshire-vermont',
    name: 'Wilshire/Vermont',
    latitude: 34.0620,
    longitude: -118.2910,
    lines: ['purple'],
    address: '3010 Wilshire Blvd, Los Angeles, CA 90010'
  },

  // Blue Line Stations
  {
    id: 'blue-7th-street',
    name: '7th Street/Metro Center',
    latitude: 34.0470,
    longitude: -118.2580,
    lines: ['blue'],
    address: '700 S Flower St, Los Angeles, CA 90017'
  },
  {
    id: 'blue-pico',
    name: 'Pico',
    latitude: 34.0450,
    longitude: -118.2580,
    lines: ['blue'],
    address: '1200 S Flower St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-grand',
    name: 'Grand/LATTC',
    latitude: 34.0430,
    longitude: -118.2580,
    lines: ['blue'],
    address: '1201 S Grand Ave, Los Angeles, CA 90015'
  },
  {
    id: 'blue-san-pedro',
    name: 'San Pedro',
    latitude: 34.0410,
    longitude: -118.2580,
    lines: ['blue'],
    address: '1400 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-washington',
    name: 'Washington',
    latitude: 34.0390,
    longitude: -118.2580,
    lines: ['blue'],
    address: '1600 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-vernon',
    name: 'Vernon',
    latitude: 34.0370,
    longitude: -118.2580,
    lines: ['blue'],
    address: '1800 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-slauson',
    name: 'Slauson',
    latitude: 34.0350,
    longitude: -118.2580,
    lines: ['blue'],
    address: '2000 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-florence',
    name: 'Florence',
    latitude: 34.0330,
    longitude: -118.2580,
    lines: ['blue'],
    address: '2200 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-firestone',
    name: 'Firestone',
    latitude: 34.0310,
    longitude: -118.2580,
    lines: ['blue'],
    address: '2400 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-103rd-watts',
    name: '103rd Street/Watts Towers',
    latitude: 34.0290,
    longitude: -118.2580,
    lines: ['blue'],
    address: '2600 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-rosa-parks',
    name: 'Rosa Parks',
    latitude: 34.0270,
    longitude: -118.2580,
    lines: ['blue'],
    address: '2800 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-imperial-wilmington',
    name: 'Imperial/Wilmington',
    latitude: 34.0250,
    longitude: -118.2580,
    lines: ['blue'],
    address: '3000 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-compton',
    name: 'Compton',
    latitude: 34.0230,
    longitude: -118.2580,
    lines: ['blue'],
    address: '3200 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-artesia',
    name: 'Artesia',
    latitude: 34.0210,
    longitude: -118.2580,
    lines: ['blue'],
    address: '3400 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-del-amo',
    name: 'Del Amo',
    latitude: 34.0190,
    longitude: -118.2580,
    lines: ['blue'],
    address: '3600 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-wardlow',
    name: 'Wardlow',
    latitude: 34.0170,
    longitude: -118.2580,
    lines: ['blue'],
    address: '3800 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-willowbrook',
    name: 'Willowbrook',
    latitude: 34.0150,
    longitude: -118.2580,
    lines: ['blue'],
    address: '4000 S San Pedro St, Los Angeles, CA 90015'
  },
  {
    id: 'blue-long-beach',
    name: 'Long Beach',
    latitude: 34.0130,
    longitude: -118.2580,
    lines: ['blue'],
    address: '4200 S San Pedro St, Los Angeles, CA 90015'
  }
];

export const metroRoutes: MetroRoute[] = [
  {
    id: 'red-line',
    name: 'Red Line',
    color: '#ff0000',
    stations: metroStations.filter(station => station.lines.includes('red')),
    coordinates: [
      [34.0556, -118.2344], // Union Station
      [34.0550, -118.2430], // Civic Center
      [34.0490, -118.2500], // Pershing Square
      [34.0470, -118.2580], // 7th Street
      [34.0570, -118.2750], // Westlake
      [34.0620, -118.2910], // Wilshire/Vermont
      [34.0620, -118.3080], // Wilshire/Western
      [34.0980, -118.2910], // Vermont/Sunset
      [34.0890, -118.2910], // Vermont/Santa Monica
      [34.1020, -118.3080], // Hollywood/Western
      [34.1020, -118.3250], // Hollywood/Vine
      [34.1020, -118.3390], // Hollywood/Highland
      [34.1380, -118.3590], // Universal City
      [34.1680, -118.3770]  // North Hollywood
    ],
    frequency: 'Every 6-10 minutes',
    operatingHours: '4:00 AM - 1:00 AM',
    description: 'Connects Downtown LA to North Hollywood via Hollywood'
  },
  {
    id: 'purple-line',
    name: 'Purple Line',
    color: '#800080',
    stations: metroStations.filter(station => station.lines.includes('purple')),
    coordinates: [
      [34.0556, -118.2344], // Union Station
      [34.0550, -118.2430], // Civic Center
      [34.0490, -118.2500], // Pershing Square
      [34.0470, -118.2580], // 7th Street
      [34.0620, -118.3080], // Wilshire/Western
      [34.0620, -118.3250], // Wilshire/Normandie
      [34.0620, -118.2910]  // Wilshire/Vermont
    ],
    frequency: 'Every 6-10 minutes',
    operatingHours: '4:00 AM - 1:00 AM',
    description: 'Connects Downtown LA to Koreatown via Wilshire Boulevard'
  },
  {
    id: 'blue-line',
    name: 'Blue Line',
    color: '#0066cc',
    stations: metroStations.filter(station => station.lines.includes('blue')),
    coordinates: [
      [34.0470, -118.2580], // 7th Street
      [34.0450, -118.2580], // Pico
      [34.0430, -118.2580], // Grand
      [34.0410, -118.2580], // San Pedro
      [34.0390, -118.2580], // Washington
      [34.0370, -118.2580], // Vernon
      [34.0350, -118.2580], // Slauson
      [34.0330, -118.2580], // Florence
      [34.0310, -118.2580], // Firestone
      [34.0290, -118.2580], // 103rd Street
      [34.0270, -118.2580], // Rosa Parks
      [34.0250, -118.2580], // Imperial/Wilmington
      [34.0230, -118.2580], // Compton
      [34.0210, -118.2580], // Artesia
      [34.0190, -118.2580], // Del Amo
      [34.0170, -118.2580], // Wardlow
      [34.0150, -118.2580], // Willowbrook
      [34.0130, -118.2580]  // Long Beach
    ],
    frequency: 'Every 6-10 minutes',
    operatingHours: '4:00 AM - 1:00 AM',
    description: 'Connects Downtown LA to Long Beach'
  }
]; 