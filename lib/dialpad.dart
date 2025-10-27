import 'package:flutter/material.dart';

class DialpadBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white38,
      builder: (context) => const DialpadWidget(),
    );
  }
}

class DialpadWidget extends StatefulWidget {
  const DialpadWidget({super.key});

  @override
  State<DialpadWidget> createState() => _DialpadWidgetState();
}

class _DialpadWidgetState extends State<DialpadWidget> {
  String _phoneNumber = '';

  void _addDigit(String digit) {
    setState(() {
      _phoneNumber += digit;
    });
  }

  void _deleteDigit() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _clearAll() {
    setState(() {
      _phoneNumber = '';
    });
  }

  Widget _buildDialButton(String digit) {
    return InkWell(
      onTap: () => _addDigit(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.cyan,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Phone number display
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _phoneNumber.isEmpty ? 'Enter number' : _phoneNumber,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: _phoneNumber.isEmpty ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
               /* if (_phoneNumber.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),*/
              ],
            ),
          ),
          const Spacer(),
          // Dialpad buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Row 1: 1, 2, 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialButton('1'),
                    _buildDialButton('2'),
                    _buildDialButton('3'),
                  ],

                ),
                const SizedBox(height: 15),
                // Row 2: 4, 5, 6
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialButton('4'),
                    _buildDialButton('5'),
                    _buildDialButton('6'),
                  ],
                ),
                const SizedBox(height: 15),
                // Row 3: 7, 8, 9
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialButton('7'),
                    _buildDialButton('8'),
                    _buildDialButton('9'),
                  ],
                ),
                const SizedBox(height: 15),
                // Row 4: *, 0, #
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialButton('*'),
                    _buildDialButton('0'),
                    _buildDialButton('#'),
                  ],
                ),
                const SizedBox(height: 30),
                // Delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: (){},
                      icon: const Icon(Icons.dialpad),
                      iconSize: 30,
                    ),
                    IconButton(
                        onPressed: (){},
                        icon: const Icon(Icons.phone),
                        iconSize: 30,
                    ),
                    IconButton(
                      onPressed: _deleteDigit,
                      icon: const Icon(Icons.backspace_outlined),
                      iconSize: 30,
                      color: Colors.grey[700],
                      onLongPress: _clearAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}