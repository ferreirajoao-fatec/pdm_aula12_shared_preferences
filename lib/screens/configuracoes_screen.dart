import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final Function(bool) onTemaAlterado;

  const ConfiguracoesScreen({super.key, required this.onTemaAlterado});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _service = PreferencesService();
  final _nomeController = TextEditingController();
  final _tarefaController = TextEditingController();

  bool _modoEscuro = false;
  bool _carregando = true;
  DateTime? _ultimoAcesso;
  List<Map<String, dynamic>> _tarefas = [];

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tarefaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferencias() async {
    final nome = await _service.obterNomeUsuario();
    final modoEscuro = await _service.obterModoEscuro();
    final ultimoAcesso = await _service.obterUltimoAcesso();
    final tarefas = await _service.obterTarefas();

    // Lê o acesso anterior antes de sobrescrever com o acesso atual
    await _service.registrarUltimoAcesso();

    setState(() {
      _nomeController.text = nome;
      _modoEscuro = modoEscuro;
      _ultimoAcesso = ultimoAcesso;
      _tarefas = tarefas;
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencias() async {
    await _service.salvarNomeUsuario(_nomeController.text);
    await _service.salvarModoEscuro(_modoEscuro);

    widget.onTemaAlterado(_modoEscuro);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas com sucesso!')),
      );
    }
  }

  Future<void> _redefinirPadroes() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir Padrões'),
        content: const Text(
          'Todas as preferências e tarefas salvas serão apagadas. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await _service.limparTudo();

    setState(() {
      _nomeController.text = PreferencesService.nomePadrao;
      _modoEscuro = false;
      _ultimoAcesso = null;
      _tarefas = [];
    });
    widget.onTemaAlterado(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências redefinidas para o padrão.')),
      );
    }
  }

  Future<void> _adicionarTarefa() async {
    final titulo = _tarefaController.text.trim();
    if (titulo.isEmpty) return;

    setState(() {
      _tarefas.add({
        'titulo': titulo,
        'concluida': false,
        'criadaEm': DateTime.now().toIso8601String(),
      });
      _tarefaController.clear();
    });
    await _service.salvarTarefas(_tarefas);
  }

  Future<void> _alternarTarefa(int index, bool concluida) async {
    setState(() => _tarefas[index]['concluida'] = concluida);
    await _service.salvarTarefas(_tarefas);
  }

  Future<void> _removerTarefa(int index) async {
    setState(() => _tarefas.removeAt(index));
    await _service.salvarTarefas(_tarefas);
  }

  String _formatarData(DateTime data) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
        'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações & Perfil'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativar Modo Escuro'),
              subtitle: const Text('Persiste o tema visual selecionado no disco'),
              value: _modoEscuro,
              onChanged: (valor) => setState(() => _modoEscuro = valor),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tarefaController,
                    decoration: const InputDecoration(
                      labelText: 'Nova tarefa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.checklist),
                    ),
                    onSubmitted: (_) => _adicionarTarefa(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _adicionarTarefa,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar tarefa',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tarefas.isEmpty
                  ? const Center(child: Text('Nenhuma tarefa salva.'))
                  : ListView.builder(
                      itemCount: _tarefas.length,
                      itemBuilder: (context, index) {
                        final tarefa = _tarefas[index];
                        final concluida = tarefa['concluida'] as bool;
                        return CheckboxListTile(
                          value: concluida,
                          onChanged: (valor) => _alternarTarefa(index, valor ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            tarefa['titulo'] as String,
                            style: TextStyle(
                              decoration: concluida ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remover tarefa',
                            onPressed: () => _removerTarefa(index),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarPreferencias,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _redefinirPadroes,
                icon: const Icon(Icons.restore),
                label: const Text('Redefinir Padrões'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _ultimoAcesso == null
                  ? 'Primeiro acesso ao aplicativo'
                  : 'Último acesso: ${_formatarData(_ultimoAcesso!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
