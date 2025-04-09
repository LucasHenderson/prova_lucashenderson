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
      title: 'Usuários e CEP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF4169E1),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4169E1),
        ),
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
        'cep': cep,
      });
      usuarioId++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuário adicionado com sucesso!')),
    );
  }

  void atualizarUsuario(String id, String primeiroNome, String sobrenome, String cep) {
    setState(() {
      final index = usuarios.indexWhere((usuario) => usuario['id'] == id);
      if (index != -1) {
        usuarios[index] = {
          'id': id,
          'primeiro_nome': primeiroNome,
          'sobrenome': sobrenome,
          'cep': cep,
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuário atualizado com sucesso!')),
    );
  }

  void deletarUsuario(String id) {
    setState(() {
      usuarios.removeWhere((usuario) => usuario['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuário removido com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Usuários"),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: usuarios.isEmpty
            ? Center(
                child: Text(
                  "Nenhum usuário cadastrado",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              )
            : ListView.builder(
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return ItemList(
                    usuario: usuario,
                    aoEditar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaFormularioUsuario(
                            aoSalvar: (primeiroNome, sobrenome, cep) =>
                                atualizarUsuario(usuario['id']!, primeiroNome, sobrenome, cep),
                            usuario: usuario,
                          ),
                        ),
                      );
                    },
                    aoDeletar: () => deletarUsuario(usuario['id']!),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaFormularioUsuario(
              aoSalvar: adicionarUsuario,
            ),
          ),
        ),
        child: Icon(Icons.add),
        tooltip: 'Adicionar usuário',
        backgroundColor: Color(0xFF4169E1),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  final Map<String, String> usuario;
  final VoidCallback aoEditar;
  final VoidCallback aoDeletar;

  const ItemList({
    required this.usuario,
    required this.aoEditar,
    required this.aoDeletar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          "${usuario['primeiro_nome']} ${usuario['sobrenome']}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "CEP: ${usuario['cep']}",
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: Wrap(
          spacing: 12,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF4169E1)),
              onPressed: aoEditar,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: aoDeletar,
              tooltip: 'Excluir',
            ),
          ],
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
  final _cepFormatter = MaskTextInputFormatter(
    mask: "#####-###",
    filter: {"#": RegExp(r'[0-9]')},
  );

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
      appBar: AppBar(
        title: Text(widget.usuario == null ? "Adicionar Usuário" : "Editar Usuário"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CampoTexto(
                label: "Primeiro Nome",
                valorInicial: primeiroNome,
                onChanged: (valor) => primeiroNome = valor,
              ),
              SizedBox(height: 12),
              CampoTexto(
                label: "Sobrenome",
                valorInicial: sobrenome,
                onChanged: (valor) => sobrenome = valor,
              ),
              SizedBox(height: 12),
              CampoTexto(
                label: "CEP",
                valorInicial: cep,
                teclado: TextInputType.number,
                formatter: _cepFormatter,
                onChanged: (valor) => cep = valor,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text(widget.usuario == null ? "Criar Usuário" : "Atualizar Usuário"),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4169E1),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  final String label;
  final String valorInicial;
  final void Function(String)? onChanged;
  final TextInputType teclado;
  final MaskTextInputFormatter? formatter;

  const CampoTexto({
    required this.label,
    required this.valorInicial,
    this.onChanged,
    this.teclado = TextInputType.text,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: valorInicial,
      onChanged: onChanged,
      keyboardType: teclado,
      inputFormatters: formatter != null ? [formatter!] : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (valor) => valor!.isEmpty ? "Informe o $label" : null,
    );
  }
}
