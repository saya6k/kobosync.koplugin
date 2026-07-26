-- Brazilian Portuguese (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 livros",
    ["%1 columns"] =
        "%1 colunas",
    ["%1 series, %2 books"] =
        "%1 séries, %2 livros",
    ["(downloaded only)"] =
        "(somente baixados)",
    ["Browse server library"] =
        "Explorar biblioteca do servidor",
    ["Cancel"] =
        "Cancelar",
    ["Cover grid"] =
        "Grade de capas",
    ["Delete"] =
        "Excluir",
    ["Download"] =
        "Baixar",
    ["Download all %1 books"] =
        "Baixar todos os %1 livros",
    ["Download folder: %1"] =
        "Pasta de download: %1",
    ["Downloaded: %1"] =
        "Baixados: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "Baixa todos os livros da biblioteca e busca os novos conforme chegam; em uma primeira sincronização isso significa a biblioteca inteira. Quando desativado, a sincronização apenas atualiza o catálogo e os livros são baixados um a um pelo navegador da biblioteca do servidor.",
    ["Every %1 minutes"] =
        "A cada %1 minutos",
    ["Failed downloads: %1"] =
        "Downloads com falha: %1",
    ["Failed: %1"] =
        "Com falha: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "Prefixo completo do Kobo Sync, incluindo o token pessoal, como mostrado pelo seu servidor (calibre-web: Perfil → Token do Kobo Sync).",
    ["Grid columns: %1"] =
        "Colunas da grade: %1",
    ["Jump"] =
        "Ir",
    ["Keep"] =
        "Manter",
    ["Keep every book on this device: %1"] =
        "Manter todos os livros neste dispositivo: %1",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Falha no Kobo Sync: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync concluído.\nNovos: %1  Alterados: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync interrompido: %1\nNovos: %2  Alterados: %3\n\nSincronizar novamente continuará daqui.",
    ["Kobo Sync library"] =
        "Biblioteca do Kobo Sync",
    ["Kobo Sync server URL"] =
        "URL do servidor Kobo Sync",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync parado.\nNovos: %1  Alterados: %2\n\nA próxima sincronização continuará daqui.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: %1 livro(s) foram removidos no servidor. Excluir os arquivos locais?\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: %1 baixados.",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 itens, página %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: já está sincronizando.",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: baixar %1 livro(s) de “%2”?\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: baixar %1 livro(s) para este dispositivo agora?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: falha ao baixar: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: baixando\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: baixando %1 de %2\n%3\n\nToque para cancelar.",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: esquecer o estado de sincronização e o catálogo?\nOs arquivos baixados são mantidos. A próxima sincronização será completa.",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: nenhum formato disponível para download deste livro.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: defina primeiro a URL do servidor.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: estado redefinido.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: parando após a página atual.\n\nO que já foi sincronizado é mantido, e sincronizar novamente continuará daqui.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: sincronizar",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: sincronizando…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: sincronizando o progresso de leitura…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: o servidor tem um progresso mais recente (%1 %). Ir para lá?",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: “%1” já está neste dispositivo.",
    ["Last synced: %1"] =
        "Última sincronização: %1",
    ["Matches book titles and series names."] =
        "Pesquisa em títulos de livros e nomes de séries.",
    ["Missing locally: %1"] =
        "Faltando localmente: %1",
    ["Not now"] =
        "Agora não",
    ["Off"] =
        "Desligado",
    ["On"] =
        "Ativado",
    ["Reading progress: %1 sent, %2 received"] =
        "Progresso de leitura: %1 enviados, %2 recebidos",
    ["Reset"] =
        "Redefinir",
    ["Reset sync"] =
        "Redefinir sincronização",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Só é executada com o Wi-Fi já ligado e apenas atualiza o catálogo: uma execução automática nunca inicia downloads, e as exclusões encontradas aguardam a próxima sincronização iniciada por você.",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "Executa a mesma sincronização automática assim que o dispositivo estiver on-line, em vez de após uma espera fixa: apenas o catálogo, e abandonada se a rede não aparecer em cinco minutos.",
    ["Save"] =
        "Salvar",
    ["Search"] =
        "Pesquisar",
    ["Search the server library"] =
        "Pesquisar na biblioteca do servidor",
    ["Search: %1"] =
        "Pesquisa: %1",
    ["Search…"] =
        "Pesquisar…",
    ["Server: %1"] =
        "Servidor: %1",
    ["Set server URL"] =
        "Definir URL do servidor",
    ["Show all books"] =
        "Mostrar todos os livros",
    ["Show downloaded only"] =
        "Mostrar somente baixados",
    ["Stay"] =
        "Ficar",
    ["Stop synchronizing"] =
        "Parar a sincronização",
    ["Sync automatically: every %1 minutes"] =
        "Sincronizar automaticamente: a cada %1 minutos",
    ["Sync automatically: off"] =
        "Sincronizar automaticamente: desligado",
    ["Sync when KOReader starts: %1"] =
        "Sincronizar ao iniciar o KOReader: %1",
    ["Synchronize now"] =
        "Sincronizar agora",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "Sincroniza a biblioteca e o progresso de leitura com um servidor Kobo Sync auto-hospedado ",
    ["Text list"] =
        "Lista de texto",
    ["Upload reading progress when closing a book: %1"] =
        "Enviar o progresso de leitura ao fechar um livro: %1",
    ["cannot write to the cover cache"] =
        "não foi possível gravar no cache de capas",
    ["never"] =
        "nunca",
    ["no cover URL for this server"] =
        "nenhuma URL de capa para este servidor",
    ["the server took too long to respond"] =
        "o servidor demorou demais para responder",
    ["this book was synced before covers were supported"] =
        "este livro foi sincronizado antes do suporte a capas",
    ["unknown error"] =
        "erro desconhecido",
    ["…and %1 more"] =
        "… e mais %1",
}
