# Princípios de Clean Code — Exemplos Detalhados

## KISS — Keep It Simple

### ❌ Violação
```typescript
function verificarElegibilidade(usuario: Usuario): boolean {
  let elegivel = false;
  if (usuario !== null) {
    if (usuario.idade !== undefined) {
      if (usuario.idade >= 18) {
        if (usuario.ativo === true) {
          elegivel = true;
        }
      }
    }
  }
  return elegivel;
}
```

### ✅ Refatorado
```typescript
function verificarElegibilidade(usuario: Usuario): boolean {
  return usuario?.idade >= 18 && usuario?.ativo === true;
}
```

---

## DRY — Don't Repeat Yourself

### ❌ Violação
```typescript
function calcularImpostoLivro(preco: number): number {
  return preco * 0.1;
}
function calcularImpostoEletronico(preco: number): number {
  return preco * 0.1;
}
function calcularImpostoBrinquedo(preco: number): number {
  return preco * 0.1;
}
```

### ✅ Refatorado
```typescript
const TAXA_IMPOSTO = 0.1;

function calcularImposto(preco: number): number {
  return preco * TAXA_IMPOSTO;
}
```

---

## TDA — Tell, Don't Ask

### ❌ Violação
```typescript
// Código externo "pergunta" o estado e decide fora da classe
if (conta.getSaldo() >= valor) {
  conta.setSaldo(conta.getSaldo() - valor);
  console.log("Saque realizado");
} else {
  console.log("Saldo insuficiente");
}
```

### ✅ Refatorado
```typescript
class Conta {
  private saldo: number;

  sacar(valor: number): void {
    if (this.saldo < valor) {
      throw new Error("Saldo insuficiente");
    }
    this.saldo -= valor;
  }
}

// Quem chama apenas diz o que fazer:
conta.sacar(valor);
```

---

## SOLID — OCP com Pagamentos

### ❌ Violação (modifica a classe a cada novo tipo)
```typescript
class ProcessadorDePagamento {
  processar(tipo: string, valor: number): void {
    if (tipo === "pix") { /* lógica pix */ }
    else if (tipo === "cartao") { /* lógica cartão */ }
    else if (tipo === "boleto") { /* lógica boleto */ }
    // para adicionar cripto, edita aqui...
  }
}
```

### ✅ Refatorado (aberto para extensão, fechado para modificação)
```typescript
interface MetodoPagamento {
  processar(valor: number): void;
}

class PagamentoPix implements MetodoPagamento {
  processar(valor: number): void { /* lógica pix */ }
}

class PagamentoCartao implements MetodoPagamento {
  processar(valor: number): void { /* lógica cartão */ }
}

// Adicionar novo: basta criar nova classe, sem tocar nas existentes
class PagamentoCripto implements MetodoPagamento {
  processar(valor: number): void { /* lógica cripto */ }
}

class ProcessadorDePagamento {
  processar(metodo: MetodoPagamento, valor: number): void {
    metodo.processar(valor);
  }
}
```

---

## SOLID — DIP com Notificações

### ❌ Violação (acoplado à implementação concreta)
```typescript
class PedidoService {
  private emailService = new EmailService(); // acoplamento direto

  confirmar(pedido: Pedido): void {
    // processa pedido...
    this.emailService.enviar(pedido.email, "Pedido confirmado");
  }
}
```

### ✅ Refatorado (depende de abstração)
```typescript
interface NotificacaoService {
  notificar(destinatario: string, mensagem: string): void;
}

class PedidoService {
  constructor(private notificacao: NotificacaoService) {}

  confirmar(pedido: Pedido): void {
    // processa pedido...
    this.notificacao.notificar(pedido.email, "Pedido confirmado");
  }
}

// Fácil de testar: injeta um mock
// Fácil de estender: troca por SMS sem mudar PedidoService
```
