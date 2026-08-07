unit UnitInicializaClasses;

interface
type
	TInicializarClasses = class
    class procedure Iniciar;
  end;

implementation

{ TInicializarClasses }

uses UnitFornecedores.Model, UnitDatabase, UnitCidade.Model, UnitEmpresa.Model,
  UnitEstado.Model, UnitFuncionarios.Model, UnitGrupos.Model,
  UnitSubGrupos.Model, UnitProdutos.Model, UnitTamanho.Model,
  UnitTotalizadores.Model, UnitUnidadeMedida.Model, UnitUsuarios.Model,
  UnitGrades.Model, UnitTransferencia.Model, UnitTransferenciaItem.Model, UnitClientes.Model;

class procedure TInicializarClasses.Iniciar;
var
  Fornecedores: TFornecedores;
  Cidade: TCidade;
  Empresa: TEmpresa;
  Estado: TEstado;
  Funcionarios: TFuncionarios;
  Grupos: TGrupos;
  SubGrupos: TSubGrupos;
  Produtos: TProdutos;
  Tamanho: TTamanho;
  Totalizadores: TTotalizadores;
  UnidadeMedida: TUnidadeMedida;
  Usuarios: TUsuarios;
  Grades: TGrades;
  Transferencia: TTransferencia;
  TransferenciaItem: TTransferenciaItem;
begin
	Writeln('Inicializando classes');
	Fornecedores := TFornecedores.Create(TDatabase.Connection);  
  try
    Fornecedores.CriaTabela;
    
  finally
    Fornecedores.DisposeOf;
  end;
  Cidade := TCidade.Create(TDatabase.Connection);
  try
    Cidade.CriaTabela;
  finally
    Cidade.DisposeOf;
  end;
  Empresa := TEmpresa.Create(TDatabase.Connection);
  try
    Empresa.CriaTabela;
  finally
    Empresa.DisposeOf;
  end;
  Estado := TEstado.Create(TDatabase.Connection);
  try
    Estado.CriaTabela;
  finally
    Estado.DisposeOf;
  end;
  Funcionarios := TFuncionarios.Create(TDatabase.Connection);
  try
    Funcionarios.CriaTabela;
  finally
    Funcionarios.DisposeOf;
  end;
  Grupos := TGrupos.Create(TDatabase.Connection);
  try
    Grupos.CriaTabela;
  finally
    Grupos.DisposeOf;
  end;
  SubGrupos := TSubGrupos.Create(TDatabase.Connection);
  try
    SubGrupos.CriaTabela;
  finally
    SubGrupos.DisposeOf;
  end;
  Produtos := TProdutos.Create(TDatabase.Connection);
  try
    Produtos.CriaTabela;
  finally
    Produtos.DisposeOf;
  end;
  Tamanho := TTamanho.Create(TDatabase.Connection);
  try
    Tamanho.CriaTabela;
  finally
    Tamanho.DisposeOf;
  end;
  Grades := TGrades.Create(TDatabase.Connection);
  try
    Grades.CriaTabela;
  finally
    Grades.DisposeOf;
  end;
  Totalizadores := TTotalizadores.Create(TDatabase.Connection);
  try
    Totalizadores.CriaTabela;
  finally
    Totalizadores.DisposeOf;
  end;
  UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection);
  try
    UnidadeMedida.CriaTabela;
  finally
    UnidadeMedida.DisposeOf;
  end;
  Usuarios := TUsuarios.Create(TDatabase.Connection);
  try
    Usuarios.CriaTabela;
  finally
    Usuarios.DisposeOf;
  end;
  Transferencia := TTransferencia.Create(TDatabase.Connection);
  try
    Transferencia.CriaTabela;
  finally
    Transferencia.DisposeOf;
  end;
  TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection);
  try
    TransferenciaItem.CriaTabela;
  finally
    TransferenciaItem.DisposeOf;
  end;
  try
    with TClientes.Create(TDatabase.Connection) do
    try
      CriaTabela;
    finally
      DisposeOf;
    end;
  except
  end;
  Writeln('Fim inicializacao de classes');	
end;

end.
