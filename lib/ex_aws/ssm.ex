defmodule ExAws.SSM do
  @moduledoc """
  Documentation for ExAws.SSM.

  AWS API version 2014-11-06.
  """
  import ExAws.SSM.Utils

  @type decryption_opt :: {:with_decryption, boolean}
  @type pagination_opts ::
          {:max_results, pos_integer}
          | {:next_token, binary}

  @type get_parameters_by_path_opt ::
          {:recursive, boolean}
          | {:parameter_filters, list(parameter_filters)}
          | pagination_opts
          | decryption_opt

  @type parameter_value_type :: :string | :string_list | :secure_string

  @type parameter_filters :: [
          key: binary,
          option: binary,
          values: list(binary)
        ]

  @type put_parameter_opt ::
          {:allowed_pattern, binary}
          | {:description, binary}
          | {:key_id, binary}
          | {:overwrite, boolean}

  @type get_parameter_opt :: decryption_opt

  @type get_parameter_history_opt ::
          {:name, binary}
          | pagination_opts
          | decryption_opt

  @type filter :: [
          key: binary,
          values: list(binary)
        ]

  @type describe_instance_information_opt ::
          {:filter, list(filter)}
          | pagination_opts

  @doc """
  Get information about a parameter by using the parameter name.
  """
  @spec get_parameter(name :: binary) :: ExAws.Operation.JSON.t()
  @spec get_parameter(name :: binary, opts :: [get_parameter_opt]) :: ExAws.Operation.JSON.t()
  def get_parameter(name, opts \\ []) do
    params = %{
      "Name" => name,
      "WithDecryption" => opts[:with_decryption] || false
    }

    request(:get_parameter, params)
  end

  @doc """
  Get details of a parameter
  """
  @spec get_parameters(names :: list(binary)) :: ExAws.Operation.JSON.t()
  @spec get_parameters(names :: list(binary), opts :: [get_parameter_opt]) ::
          ExAws.Operation.JSON.t()
  def get_parameters(names, opts \\ []) do
    params = %{
      "Names" => names,
      "WithDecryption" => opts[:with_decryption] || false
    }

    request(:get_parameters, params)
  end

  @doc """
  Retrieve parameters in a specific hierarchy.
  """
  @spec get_parameters_by_path(path :: binary) :: ExAws.Operation.JSON.t()
  @spec get_parameters_by_path(path :: binary, opts :: [get_parameters_by_path_opt]) ::
          ExAws.Operation.JSON.t()
  def get_parameters_by_path(path, opts \\ []) do
    params =
      %{
        "Path" => path,
        "Recursive" => opts[:recursive] || false,
        "WithDecryption" => opts[:with_decryption] || false
      }
      |> maybe_add_max_results(opts)
      |> maybe_add_next_token(opts)

    params =
      case is_list(opts[:parameter_filters]) do
        false ->
          params

        true ->
          opts[:parameter_filters]
          |> Enum.map(fn filter ->
            %{
              "Key" => filter[:key],
              "Option" => filter[:option],
              "Values" => filter[:values]
            }
          end)
          |> (&Map.put(params, "ParameterFilters", &1)).()
      end

    request(:get_parameters_by_path, params)
  end

  @doc """
  Add a parameter to the system.
  """
  @spec put_parameter(
          name :: binary,
          type :: parameter_value_type,
          value :: binary,
          opts :: [put_parameter_opt]
        ) :: ExAws.Operation.JSON.t()
  def put_parameter(name, type, value, opts \\ [])
      when type in [:string, :string_list, :secure_string] do
    value_type =
      case type do
        :string -> "String"
        :string_list -> "StringList"
        :secure_string -> "SecureString"
      end

    params =
      %{
        "Name" => name,
        "Overwrite" => opts[:overwrite] || false,
        "Value" => value,
        "Type" => value_type,
        "Description" => opts[:description] || ""
      }
      |> maybe_add_key_id(opts)

    request(:put_parameter, params)
  end

  @doc """
  Delete a parameter from the system.
  """
  @spec delete_parameter(name :: binary) :: ExAws.Operation.JSON.t()
  def delete_parameter(name) do
    request(:delete_parameter, %{"Name" => name})
  end

  @doc """
  Delete a list of parameters.
  """
  @spec delete_parameters(names :: list(binary)) :: ExAws.Operation.JSON.t()
  def delete_parameters(names) do
    request(:delete_parameters, %{"Names" => names})
  end

  @doc """
  Query a list of all parameters used by the AWS account.
  """
  @spec get_parameter_history(name :: binary, opts :: [get_parameter_history_opt]) ::
          ExAws.Operation.JSON.t()
  def get_parameter_history(name, opts \\ []) do
    params =
      %{
        "Name" => name,
        "WithDecryption" => opts[:with_decryption] || false
      }
      |> maybe_add_max_results(opts)
      |> maybe_add_next_token(opts)

    request(:get_parameter_history, params)
  end

  @doc """
  Describes one or more of your instances.

  Doc: https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_DescribeInstanceInformation.html

  ## Example:
        iex> SSM.describe_instance_information(filters: [%{"Key": "InstanceIds", "Values": ["i-0EXAMPLE"]}], max_results: 10)
        %ExAws.Operation.JSON{
          before_request: nil,
          data: %{
            "Filters" => [%{Key: "InstanceIds", Values: ["i-0EXAMPLE"]}],
            "MaxResults" => 10
          },
          headers: [
            {"x-amz-target", "AmazonSSM.DescribeInstanceInformation"},
            {"content-type", "application/x-amz-json-1.1"}
          ],
          http_method: :post,
          params: %{},
          parser: #Function<1.12038698/1 in ExAws.Operation.JSON.new/2>,
          path: "/",
          service: :ssm,
          stream_builder: nil
        }
  """
  @spec describe_instance_information(opts :: [describe_instance_information_opt]) ::
          ExAws.Operation.JSON.t()
  def describe_instance_information(opts \\ []) do
    params =
      %{
        "Filters" => opts[:filters] || []
      }
      |> maybe_add_max_results(opts)
      |> maybe_add_next_token(opts)

    request(:describe_instance_information, params)
  end

  defp request(action, params) do
    operation = action |> Atom.to_string() |> Macro.camelize()

    ExAws.Operation.JSON.new(:ssm, %{
      data: params,
      headers: [
        {"x-amz-target", "AmazonSSM.#{operation}"},
        {"content-type", "application/x-amz-json-1.1"}
      ]
    })
  end
end
