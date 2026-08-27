unit UnitComEst.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/comEst')]
  [TNomeTabela('COM_EST', 'CE_CODIGO')]
  TComEst = class(TTabela)
  private
    FCeCodigo: Integer;
    FCeValor: Double;
    FCeQuantidade: Double;
    FCeIpi: Double;
    FCePro: Integer;
    FCeCom: Integer;
    FCeValorc: Double;
    FCeValorcm: Double;
    FCeValorm: Double;
    FCeValorop: Double;
    FCeValorv: Double;
    FCeGrade: Integer;
    FCeCustoMercadoria: Double;
    FCeCustoFrete: Double;
    FCeCustoOutros: Double;
    FCeCustoMedio: Double;
  public
    [TCampo('CE_CODIGO', 'NUMERIC(8,0) NOT NULL PRIMARY KEY')]
    property ceCodigo: Integer read FCeCodigo write FCeCodigo;

    [TCampo('CE_VALOR', 'NUMERIC(12,4)')]
    property ceValor: Double read FCeValor write FCeValor;

    [TCampo('CE_QUANTIDADE', 'NUMERIC(9,2)')]
    property ceQuantidade: Double read FCeQuantidade write FCeQuantidade;

    [TCampo('CE_IPI', 'NUMERIC(3,2)')]
    property ceIpi: Double read FCeIpi write FCeIpi;

    [TCampo('CE_PRO', 'NUMERIC(6,0)')]
    property cePro: Integer read FCePro write FCePro;

    [TCampo('CE_COM', 'NUMERIC(8,0)')]
    property ceCom: Integer read FCeCom write FCeCom;

    [TCampo('CE_VALORC', 'NUMERIC(12,4)')]
    property ceValorc: Double read FCeValorc write FCeValorc;

    [TCampo('CE_VALORCM', 'NUMERIC(12,4)')]
    property ceValorcm: Double read FCeValorcm write FCeValorcm;

    [TCampo('CE_VALORM', 'NUMERIC(12,4)')]
    property ceValorm: Double read FCeValorm write FCeValorm;

    [TCampo('CE_VALOROP', 'NUMERIC(12,4)')]
    property ceValorop: Double read FCeValorop write FCeValorop;

    [TCampo('CE_VALORV', 'NUMERIC(12,4)')]
    property ceValorv: Double read FCeValorv write FCeValorv;

    [TCampo('CE_GRADE', 'INTEGER')]
    property ceGrade: Integer read FCeGrade write FCeGrade;

    [TCampo('CE_CUSTO_MERCADORIA', 'NUMERIC(12,4)')]
    property ceCustoMercadoria: Double read FCeCustoMercadoria write FCeCustoMercadoria;

    [TCampo('CE_CUSTO_FRETE', 'NUMERIC(12,4)')]
    property ceCustoFrete: Double read FCeCustoFrete write FCeCustoFrete;

    [TCampo('CE_CUSTO_OUTROS', 'NUMERIC(12,4)')]
    property ceCustoOutros: Double read FCeCustoOutros write FCeCustoOutros;

    [TCampo('CE_CUSTO_MEDIO', 'NUMERIC(12,4)')]
    property ceCustoMedio: Double read FCeCustoMedio write FCeCustoMedio;
  end;

implementation

end.
