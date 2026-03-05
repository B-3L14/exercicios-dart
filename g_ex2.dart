import 'dart:async';

enum StatusPedido { pendente, confirmado, preparando, entregue, cancelado }

class ItemPedido {
  final String nomeProduto;
  final int quantidade;
  final double precoUnitario;
  final String? observacao;

  const ItemPedido({
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
    this.observacao,
  });
}

class Pedido {
  final String id;
  final String idUsuario;
  final List<ItemPedido> itens;
  final StatusPedido status;
  final DateTime criadoEm;

  const Pedido({
    required this.id,
    required this.idUsuario,
    required this.itens,
    required this.status,
    required this.criadoEm,
  });
}

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String mensagem;
  const Failure(this.mensagem);
}

class RelatorioPedidos {
  final List<Pedido> _pedidos;

  const RelatorioPedidos(this._pedidos);

  Iterable<Pedido> get _pedidosValidos =>
      _pedidos.where((p) => p.status != StatusPedido.cancelado);

  double get totalGeral {
    return _pedidosValidos.fold(0.0, (somaAcumulada, pedido) {
      final totalPedido = pedido.itens.fold(
        0.0,
        (somaItem, item) => somaItem + (item.precoUnitario * item.quantidade),
      );
      return somaAcumulada + totalPedido;
    });
  }

  double get ticketMedio {
    final validos = _pedidosValidos;
    if (validos.isEmpty) return 0.0;
    return totalGeral / validos.length;
  }

  Map<StatusPedido, List<Pedido>> get pedidosPorStatus {
    final mapa = <StatusPedido, List<Pedido>>{};
    for (final pedido in _pedidos) {
      mapa.putIfAbsent(pedido.status, () => []).add(pedido);
    }
    return mapa;
  }

  List<Pedido> pedidosDoUsuario(String idUsuario) {
    return _pedidos.where((p) => p.idUsuario == idUsuario).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  bool get contemPedidoUrgente {
    final agora = DateTime.now();
    return _pedidos.any(
      (p) =>
          p.status == StatusPedido.pendente &&
          agora.difference(p.criadoEm).inMinutes > 30,
    );
  }

  String get produtoMaisVendido {
    if (_pedidos.isEmpty) return 'Nenhum pedido registrado';

    final quantidadesAgregadas = _pedidos
        .expand((pedido) => pedido.itens)
        .fold<Map<String, int>>(<String, int>{}, (mapa, item) {
          mapa[item.nomeProduto] =
              (mapa[item.nomeProduto] ?? 0) + item.quantidade;
          return mapa;
        });

    if (quantidadesAgregadas.isEmpty) return 'Nenhum item vendido';

    final maisVendido = quantidadesAgregadas.entries.reduce(
      (atual, proximo) => atual.value > proximo.value ? atual : proximo,
    );

    return maisVendido.key;
  }
}

Future<Result<RelatorioPedidos>> gerarRelatorio(List<Pedido> pedidos) async {
  await Future.delayed(const Duration(seconds: 1));

  if (pedidos.isEmpty) {
    return const Failure('A lista de pedidos está vazia.');
  }

  return Success(RelatorioPedidos(pedidos));
}

void main() async {
  final horaAtual = DateTime.now();

  final pedidosTeste = [
    Pedido(
      id: '1',
      idUsuario: 'U1',
      status: StatusPedido.entregue,
      criadoEm: horaAtual.subtract(const Duration(days: 1)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Pizza Margherita',
          quantidade: 2,
          precoUnitario: 45.0,
        ),
        const ItemPedido(
          nomeProduto: 'Refrigerante',
          quantidade: 2,
          precoUnitario: 8.0,
        ),
      ],
    ),
    Pedido(
      id: '2',
      idUsuario: 'U2',
      status: StatusPedido.pendente,
      criadoEm: horaAtual.subtract(const Duration(minutes: 40)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Hambúrguer',
          quantidade: 3,
          precoUnitario: 35.0,
        ),
      ],
    ),
    Pedido(
      id: '3',
      idUsuario: 'U1',
      status: StatusPedido.confirmado,
      criadoEm: horaAtual.subtract(const Duration(hours: 2)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Batata Frita',
          quantidade: 1,
          precoUnitario: 15.0,
        ),
      ],
    ),
    Pedido(
      id: '4',
      idUsuario: 'U3',
      status: StatusPedido.cancelado,
      criadoEm: horaAtual.subtract(const Duration(days: 2)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Pizza Margherita',
          quantidade: 5,
          precoUnitario: 45.0,
        ),
      ],
    ),
    Pedido(
      id: '5',
      idUsuario: 'U4',
      status: StatusPedido.preparando,
      criadoEm: horaAtual.subtract(const Duration(minutes: 15)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Salada',
          quantidade: 2,
          precoUnitario: 25.0,
        ),
        const ItemPedido(
          nomeProduto: 'Suco',
          quantidade: 2,
          precoUnitario: 10.0,
        ),
      ],
    ),
    Pedido(
      id: '6',
      idUsuario: 'U2',
      status: StatusPedido.pendente,
      criadoEm: horaAtual.subtract(const Duration(minutes: 10)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Hambúrguer',
          quantidade: 1,
          precoUnitario: 35.0,
        ), // Pendente, mas não urgente
      ],
    ),
    Pedido(
      id: '7',
      idUsuario: 'U5',
      status: StatusPedido.entregue,
      criadoEm: horaAtual.subtract(const Duration(days: 3)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Hambúrguer',
          quantidade: 4,
          precoUnitario: 35.0,
        ),
      ],
    ),
    Pedido(
      id: '8',
      idUsuario: 'U1',
      status: StatusPedido.preparando,
      criadoEm: horaAtual.subtract(const Duration(minutes: 5)),
      itens: [
        const ItemPedido(
          nomeProduto: 'Sobremesa',
          quantidade: 2,
          precoUnitario: 18.0,
        ),
      ],
    ),
  ];

  print('Buscando dados e gerando relatório...\n');

  final resultado = await gerarRelatorio(pedidosTeste);

  switch (resultado) {
    case Success(value: final relatorio):
      print('=== RELATÓRIO DE PEDIDOS ===');
      print(
        'Total Geral (Válidos): R\$ ${relatorio.totalGeral.toStringAsFixed(2)}',
      );
      print('Ticket Médio: R\$ ${relatorio.ticketMedio.toStringAsFixed(2)}');
      print('Produto Mais Vendido: ${relatorio.produtoMaisVendido}');
      print(
        'Existem pedidos urgentes? ${relatorio.contemPedidoUrgente ? 'Sim' : 'Não'}',
      );

      print('\nPedidos Agrupados por Status:');
      for (final entrada in relatorio.pedidosPorStatus.entries) {
        print(' - ${entrada.key.name}: ${entrada.value.length} pedido(s)');
      }

      print('\nHistórico do Usuário U1:');
      final pedidosU1 = relatorio.pedidosDoUsuario('U1');
      for (final p in pedidosU1) {
        print(' - Pedido ${p.id} (${p.status.name}), Criado em: ${p.criadoEm}');
      }
      break;

    case Failure(mensagem: final msgErro):
      print('ERRO AO GERAR RELATÓRIO: $msgErro');
      break;
  }
}
