# sanca-brew-goomer-mobile

App iOS 100% nativo (Swift + SwiftUI + Combine) da loja **Sanca Brew - A Casa do Cervejeiro**,
que consome o catálogo da vitrine Goomer de forma nativa, sem WebView no fluxo principal.

## Como rodar

```bash
brew install xcodegen      # gerador do .xcodeproj (o projeto não é versionado)
xcodegen generate
open SancaBrew.xcodeproj
```

Build e testes pela linha de comando:

```bash
xcodebuild -project SancaBrew.xcodeproj -scheme SancaBrew \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Requisitos: Xcode 16+ (validado no Xcode 26.6), iOS 17.0 como deployment target.

## Arquitetura

MVVM + Data Providers, com injeção por protocolo:

```
SancaBrew/
  App/          SancaBrewApp, RootView (tabs), Theme
  Core/         HTTPClient, HTTPRequest, APIError, GoomerEnvironment, utilidades
  Domain/       Modelos (Store, Product, Menu, UserSession) e protocolos de provider
  Data/         Providers Goomer/Firebase, cache em disco, Keychain
  Features/     Bootstrap (splash/preload), Menu, Search, Product, Cart, Auth, Profile, Store
SancaBrewTests/ Testes de decode, carrinho e sessão (fixtures reais da Goomer)
```

- **Preload ("robô")**: `CatalogRepository.bootstrap()` carrega dados da loja, cardápio completo
  e pré-aquece as primeiras imagens antes de liberar a UI; o estado é publicado via Combine para
  a `SplashView`. O último catálogo válido fica em cache em disco para abertura offline/instantânea.
- **Catálogo nativo**: categorias, detalhe de produto (variações de preço, observação),
  busca com debounce e carrinho com resumo para WhatsApp.
- **Rede**: async/await sobre `URLSession` com decoding tolerante aos tipos mistos da API Goomer.

## Autenticação

A Goomer usa SSO Firebase (projeto `goomer-sso`). O provider de e-mail/senha está **desabilitado**
no projeto deles (`PASSWORD_LOGIN_DISABLED`), e as opções oficiais são "Continuar com Google" e
"Continuar com e-mail" (código/OTP).

O app cobre os dois caminhos:

- `FirebaseAuthProvider`: cliente REST nativo do Identity Toolkit (senha, Google IdP, refresh e
  reset). Pronto para funcionar caso o provider de senha seja habilitado ou o projeto passe a ter
  um client iOS registrado.
- `GoomerWebAuthView`: usa o SSO oficial da Goomer e promove a sessão Firebase resultante
  (`FirebaseWebSession`) para uma `UserSession` nativa, guardada no Keychain e renovada por
  refresh token.

O fechamento do pedido continua no fluxo web autenticado da Goomer (as APIs de pedido não são
públicas), com o envio por WhatsApp como alternativa.
