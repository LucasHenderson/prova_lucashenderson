import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';

void main() {
  runApp(MeuApp());
}

class MeuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TelaListaUsuarios(),
    );
  }
}

class TelaListaUsuarios extends StatefulWidget {
  @override
  _TelaListaUsuariosState createState() => _TelaListaUsuariosState();
}

class _TelaListaUsuariosState extends State<TelaListaUsuarios> {
  List<Map<String, String>> usuarios = [];
  int usuarioId = 1;

  void adicionarUsuario(String primeiroNome, String sobrenome, String cep) {
    setState(() {
      usuarios.add({
        'id': usuarioId.toString(),
        'primeiro_nome': primeiroNome,
        'sobrenome': sobrenome,
        'cep': cep
      });
      usuarioId++;
    });
  }

  void atualizarUsuario(String id, String primeiroNome, String sobrenome, String cep) {
    setState(() {
      final index = usuarios.indexWhere((usuario) => usuario['id'] == id);
      if (index != -1) {
        usuarios[index] = {
          'id': id,
          'primeiro_nome': primeiroNome,
          'sobrenome': sobrenome,
          'cep': cep
        };
      }
    });
  }

  void deletarUsuario(String id) {
    setState(() {
      usuarios.removeWhere((usuario) => usuario['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lista de Usuários")),
      body: Center(
        child: usuarios.isEmpty
            ? Text(
                "Nenhum usuário cadastrado",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              )
            : Padding(
                padding: EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          "${usuario['primeiro_nome']} ${usuario['sobrenome']}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "CEP: ${usuario['cep']}",
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TelaFormularioUsuario(
                                    aoSalvar: (primeiroNome, sobrenome, cep) =>
                                        atualizarUsuario(usuario['id']!, primeiroNome, sobrenome, cep),
                                    usuario: usuario,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deletarUsuario(usuario['id']!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaFormularioUsuario(
              aoSalvar: adicionarUsuario,
            ),
          ),
        ),
      ),
    );
  }
}

class TelaFormularioUsuario extends StatefulWidget {
  final Function(String, String, String) aoSalvar;
  final Map<String, String>? usuario;

  TelaFormularioUsuario({required this.aoSalvar, this.usuario});

  @override
  _TelaFormularioUsuarioState createState() => _TelaFormularioUsuarioState();
}

class _TelaFormularioUsuarioState extends State<TelaFormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _cepFormatter = MaskTextInputFormatter(mask: "#####-###", filter: {"#": RegExp(r'[0-9]')});
  late String primeiroNome;
  late String sobrenome;
  late String cep;

  @override
  void initState() {
    super.initState();
    primeiroNome = widget.usuario?['primeiro_nome'] ?? "";
    sobrenome = widget.usuario?['sobrenome'] ?? "";
    cep = widget.usuario?['cep'] ?? "";
  }

  Future<bool> validarCep(String cep) async {
    final response = await http.get(Uri.parse("https://viacep.com.br/ws/$cep/json/"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["erro"] == null;
    }
    return false;
  }

  void mostrarAlertaCepInvalido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("CEP Inválido"),
        content: Text("O CEP informado não é válido. Verifique e tente novamente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.usuario == null ? "Adicionar Usuário" : "Editar Usuário")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Primeiro Nome",
                  border: OutlineInputBorder(),
                ),
                initialValue: primeiroNome,
                onChanged: (value) => primeiroNome = value,
                validator: (value) => value!.isEmpty ? "Informe o primeiro nome" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Sobrenome",
                  border: OutlineInputBorder(),
                ),
                initialValue: sobrenome,
                onChanged: (value) => sobrenome = value,
                validator: (value) => value!.isEmpty ? "Informe o sobrenome" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "CEP",
                  border: OutlineInputBorder(),
                ),
                initialValue: cep,
                keyboardType: TextInputType.number,
                inputFormatters: [_cepFormatter],
                onChanged: (value) => cep = value,
                validator: (value) => value!.isEmpty ? "Informe o CEP" : null,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      bool valido = await validarCep(cep);
                      if (valido) {
                        widget.aoSalvar(primeiroNome, sobrenome, cep);
                        Navigator.pop(context);
                      } else {
                        mostrarAlertaCepInvalido();
                      }
                    }
                  },
                  child: Text(widget.usuario == null ? "Criar Usuário" : "Atualizar Usuário"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
