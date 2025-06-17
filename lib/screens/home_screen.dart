import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ticketito_drawer.dart';
import './historial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String? userName;

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  int selectedCategoryIndex = 0;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _filteredEvents = [];
  List<String> _favoriteEvents = [];

  // Lista de categorías
  final List<String> categories = [
    'TODOS',
    'CONCIERTOS',
    'TEATROS Y MUSICALES',
    'FAMILIARES'
  ];

  int _selectedIndex = 1; // 0: Buscar, 1: Inicio, 2: Mis eventos
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadFavorites();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userName = user.displayName ?? 'Usuario';
    } else {
      userName = 'Invitado';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      final events = await _apiService.getEvents(
        category: selectedCategoryIndex == 0
            ? null
            : categories[selectedCategoryIndex],
      );
      setState(() {
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar eventos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      // Aquí implementarías la llamada a tu API para obtener favoritos
      // Por ahora, mantenemos la lista vacía
      setState(() {
        _favoriteEvents = [];
      });
    } catch (e) {
      print('Error al cargar favoritos: $e');
    }
  }

  Future<void> _toggleFavorite(String eventId) async {
    try {
      final isFavorite = !_favoriteEvents.contains(eventId);
      await _apiService.toggleFavorite(eventId, isFavorite);
      setState(() {
        if (isFavorite) {
          _favoriteEvents.add(eventId);
        } else {
          _favoriteEvents.remove(eventId);
        }
      });
    } catch (e) {
      print('Error al actualizar favoritos: $e');
    }
  }

  Future<void> _shareEvent(Map<String, dynamic> event) async {
    try {
      await _apiService.shareEvent(event['id']);
      final shareText = '¡No te pierdas ${event['title']}!\n'
          'Lugar: ${event['location']}\n'
          'Precio: \$${event['price']}\n'
          'Fecha: ${event['date']}\n\n'
          'Descúbrelo en Ticketito: https://backend-00/api/events/${event['id']}';

      await Share.share(shareText);
    } catch (e) {
      print('Error al compartir evento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: TicketitoDrawer(user: FirebaseAuth.instance.currentUser),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            // Buscar
            Center(
                child: Text('Buscar', style: TextStyle(color: Colors.white))),
            // Home principal
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 30),
                        _buildNewEventsSection(),
                        const SizedBox(height: 30),
                        _buildCategoriesSection(),
                        const SizedBox(height: 20),
                        _buildEventsList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Mis eventos (Historial)
            const HistorialScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Icon
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            const Spacer(),

            // Welcome Text
            Expanded(
              flex: 3,
              child: Text(
                '¡Bienvenido${userName != null ? ', $userName!' : '!'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Notification and Settings Icons
            const Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 15),
                Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Busca artista, ciudad, evento...',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildNewEventsSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF88)),
      );
    }

    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          'No hay eventos disponibles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Nuevos eventos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Featured Event Card
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              // Event image
              CachedNetworkImage(
                imageUrl: _filteredEvents[0]['image'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[700],
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[700],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ),
              ),

              // Event info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _filteredEvents[0]['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _filteredEvents[0]['location'],
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite and share buttons
              Positioned(
                top: 15,
                right: 15,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleFavorite(_filteredEvents[0]['id']),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _favoriteEvents.contains(_filteredEvents[0]['id'])
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _shareEvent(_filteredEvents[0]),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.asMap().entries.map((entry) {
              int index = entry.key;
              String category = entry.value;
              bool isSelected = selectedCategoryIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategoryIndex = index;
                  });
                  // Aquí filtrarás los eventos por categoría
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00FF88)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00FF88)
                          : Colors.grey[600]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF88)),
      );
    }

    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          'No hay eventos disponibles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return Column(
      children: _filteredEvents
          .map((event) => GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/event', arguments: event);
                },
                child: _buildEventCard(event),
              ))
          .toList(),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _toggleFavorite(event['id']),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: _favoriteEvents.contains(event['id'])
                ? Icons.favorite
                : Icons.favorite_border,
            label: _favoriteEvents.contains(event['id'])
                ? 'Quitar favorito'
                : 'Agregar favorito',
          ),
          SlidableAction(
            onPressed: (_) => _shareEvent(event),
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Compartir',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            // Event Image
            CachedNetworkImage(
              imageUrl: event['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 15),

            // Event Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event['location'],
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(Icons.search, 'Buscar', _selectedIndex == 0, () {
            _pageController.animateToPage(0,
                duration: Duration(milliseconds: 300), curve: Curves.ease);
          }),
          _buildBottomNavItem(Icons.home, 'Inicio', _selectedIndex == 1, () {
            _pageController.animateToPage(1,
                duration: Duration(milliseconds: 300), curve: Curves.ease);
          }),
          _buildBottomNavItem(Icons.event, 'Mis eventos', _selectedIndex == 2,
              () {
            _pageController.animateToPage(2,
                duration: Duration(milliseconds: 300), curve: Curves.ease);
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00FF88) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00FF88) : Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: 30,
              color: const Color(0xFF00FF88),
            ),
        ],
      ),
    );
  }
}
