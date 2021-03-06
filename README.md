# Care Database Model

Autor: Vinícius Reis

## Introdução

Este projeto foi entregue como projeto final da disciplina de Banco de Dados, na Universidade Federal do ABC.

Este repositório contém os scripts para criação de um modelo de banco de dados relacional no PostgreSQL para uma rede de hospitais.

O modelo atende as especificações solicitadas no documento contido na pasta ```docs```.

## Execução do Modelo

Para criar o modelo basta executar o arquivo ```CreateModel.sql``` em seu banco de dados.

Com o banco criado, o arquivo ```ModelTests.sql``` pode ser executado para analisar o funcionamento do modelo, e fazer os testes solicitados nos requisitos.

Para executar cada teste de uma vez, basta descomentar uma linha de cada vez ao final do arquivo acima.

Para deletar o banco e seu *schema*, basta executar a query ```DestroyModel.sql```.

## Créditos

O modelo conceitual foi construído utilizando o software [brModelo 3](http://www.sis4.com/brModelo/), para Linux.
