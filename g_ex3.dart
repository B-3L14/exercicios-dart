import 'dart:async';
import 'dart:math';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String mensagem;
  final Object? erro;
  const Failure(this.mensagem, {this.erro});
}

class Produto {
  final String id;
  final String nome;
  final double preco;
  final String categoria;
  final bool disponivel;

  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.categoria,
    this.disponivel = true,
  });
}

class ProgressoSincronizacao {
  final int total;
  final int processados;
  final int falhas;
  final String mensagem;

  const ProgressoSincronizacao({
    required this.total,
    required this.processados,
    required this.falhas,
    required this.mensagem,
  });

  double get percentualConclusao {
    if (total == 0) return 0.0;
    
    double percentual = (processados / total) * 100;
    return double.parse(percentual.toStringAsFixed(1));
  }

  ProgressoSincronizacao copyWith({
    int? total,
    int? processados,
    int? falhas,
    String? mensagem,
  }) {
    return ProgressoSincronizacao(
      total: total ?? this.total,
      processados: processados ?? this.processados,
      falhas: falhas ?? this.falhas,
      mensagem: mensagem ?? this.mensagem,
    );
  }
}

extension SincronizacaoProdutoExtension on List<Produto> {
  
  List<Produto> get validos {
    return where((p) => p.preco > 0 && p.nome.trim().isNotEmpty && p.disponivel).toList();
  }

  Map<String, List<Produto>> get agrupadosParaSincronizacao {
    final mapa = <String, List<Produto>>{};
    
    for (final p in this) {
      mapa.putIfAbsent(p.categoria, () => []).add(p);
    }
    
    for (final lista in mapa.values) {
      lista.sort((a, b) => a.preco.compareTo(b.preco));
    }
    
    return mapa;
  }
}

class SincronizacaoService {
  final StreamController<ProgressoSincronizacao> _controller = StreamController<ProgressoSincronizacao>.broadcast();

  Stream<ProgressoSincronizacao> get progressoStream => _controller.stream;

  Future<Result<int>> sincronizar(List<Produto> produtos) async {
    int total = produtos.length;
    int sucesso = 0;
    int falha = 0;

    var estadoAtual = ProgressoSincronizacao(
      total: total,
      processados: sucesso,
      falhas: falha,
      mensagem: 'Sincronização iniciada...',
    );
    _controller.sink.add(estadoAtual);

    final random = Random();

    for (final produto in produtos) {
      int delayMs = 100 + random.nextInt(401);
      await Future.delayed(Duration(milliseconds: delayMs));

      bool isFalha = random.nextDouble() < 0.20;

      if (isFalha) {
        falha++;
        estadoAtual = estadoAtual.copyWith(
          falhas: falha,
          mensagem: 'Falha ao sincronizar: ${produto.nome}',
        );
      } else {
        sucesso++;
        estadoAtual = estadoAtual.copyWith(
          processados: sucesso,
          mensagem: 'Sucesso ao sincronizar: ${produto.nome}',
        );
      }

      _controller.sink.add(estadoAtual);
    }

    await _controller.close();

    if (sucesso > 0) {
      return Success(sucesso);
    } else {
      return Failure('Nenhum produto foi sincronizado com sucesso.');
    }
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}


void main() async {
  final produtos = [
    const Produto(id: '1', nome: 'Monitor', preco: 1200.0, categoria: 'Eletrônicos', disponivel: true),
    const Produto(id: '2', nome: 'Teclado', preco: 350.0, categoria: 'Eletrônicos', disponivel: true),
    const Produto(id: '3', nome: '', preco: 100.0, categoria: 'Eletrônicos', disponivel: true), 
    const Produto(id: '4', nome: 'Mouse', preco: 0.0, categoria: 'Eletrônicos', disponivel: true), 
    const Produto(id: '5', nome: 'Cadeira', preco: 850.0, categoria: 'Móveis', disponivel: false), 
    const Produto(id: '6', nome: 'Mesa', preco: 1500.0, categoria: 'Móveis', disponivel: true),
    const Produto(id: '7', nome: 'Caneta', preco: 5.0, categoria: 'Papelaria', disponivel: true),
    const Produto(id: '8', nome: 'Caderno', preco: 25.0, categoria: 'Papelaria', disponivel: true),
    const Produto(id: '9', nome: 'Borracha', preco: 2.0, categoria: 'Papelaria', disponivel: true),
    const Produto(id: '10', nome: 'Luminária', preco: 120.0, categoria: 'Decoração', disponivel: true),
    const Produto(id: '11', nome: 'Quadro', preco: 45.0, categoria: 'Decoração', disponivel: true),
  ];

  final listaFiltrada = produtos.validos;

  final service = SincronizacaoService();

  service.progressoStream.listen((progresso) {
    print('[${progresso.percentualConclusao}%] ${progresso.processados}/${progresso.total} processados, ${progresso.falhas} falhas - ${progresso.mensagem}');
  });

  final result = await service.sincronizar(listaFiltrada);

  print('\n--- RESULTADO DA OPERAÇÃO ---');
  switch (result) {
    case Success(value: final totalSincronizados):
      print('Operação de sincronização finalizada com êxito! $totalSincronizados itens enviados.');
    case Failure(mensagem: final msgError):
      print('Erro Crítico: $msgError');
  }

  service.dispose();
}