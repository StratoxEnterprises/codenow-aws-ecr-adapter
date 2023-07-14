package processor

import (
	"context"
	"errors"
	"fmt"
	"github.com/benthosdev/benthos/v4/public/service"
	"github.com/hashicorp/terraform-exec/tfexec"
	"log"
	"os"
	"time"
)

type TerraformProcessor struct {
	logger  *service.Logger
	counter *service.MetricCounter
	path    string
}

type Options struct {
	VarFiles []string
}

var TrfProcessorConfigSpec = service.NewConfigSpec().
	Summary("Configuration for terraform plugin").
	Field(service.NewStringField("path").Description("Path to terraform root module file"))

func init() {

	constructor := func(conf *service.ParsedConfig, mgr *service.Resources) (service.Processor, error) {
		return newTerraformProcessor(conf, mgr.Logger(), mgr.Metrics()), nil
	}

	err := service.RegisterProcessor("terraform", TrfProcessorConfigSpec, constructor)
	if err != nil {
		panic(err)
	}
}

func newTerraformProcessor(conf *service.ParsedConfig, logger *service.Logger, metrics *service.Metrics) *TerraformProcessor {

	path, err := conf.FieldString("path")
	if err != nil {
		fmt.Println(err)
		return nil
	}

	return &TerraformProcessor{
		logger:  logger,
		counter: metrics.NewCounter("TerraformProcessor"),
		path:    path,
	}
}

func (tfp *TerraformProcessor) Process(ctx context.Context, m *service.Message) (service.MessageBatch, error) {

	tfp.logger.Debug("Invoking TerraformProcessor")

	terraform, err := tfexec.NewTerraform(tfp.path, "/bin/terraform")
	if err != nil {
		tfp.logger.Errorf("error running NewTerraform: %s", err)
	}

	accountName, found := m.MetaGet("account")
	if !found {
		tfp.logger.Error("Meta 'account' not found.")
		return nil, errors.New("meta 'account' not found")
	}
	//get terraform variable from previous rest call response
	tfvarsBytes, _ := m.AsBytes()
	tfvarsTmpFile := fmt.Sprintf("%s/default-%d.tfvars", terraform.WorkingDir(), time.Now().UnixMilli())

	//write terraform variable into temporary file
	tfp.logger.Info("Creating temporary tfvars file on filesystem....")
	err = os.WriteFile(tfvarsTmpFile, tfvarsBytes, 0644)
	if err != nil {
		tfp.logger.Error(err.Error())
	}
	defer func(name string) {
		_ = os.Remove(name)
	}(tfvarsTmpFile)

	log.Println("Running Terraform init...")
	err = terraform.Init(context.Background(), tfexec.Upgrade(true),
		tfexec.BackendConfig("endpoint="+os.Getenv("TRF_STATE_AWS_S3_URL")),
		tfexec.BackendConfig("access_key="+os.Getenv("AWS_S3_ACCESS_KEY_ID")),
		tfexec.BackendConfig("secret_key="+os.Getenv("AWS_S3_SECRET_ACCESS_KEY")),
	)
	if err != nil {
		tfp.logger.Error("error terraform init.")
		return nil, err
	}

	//use terraform worskapce for given account
	tfp.logger.Debug("Switching Terraform Workspace....")
	trfWorkspace := accountName + "-default"
	_ = terraform.WorkspaceNew(context.Background(), trfWorkspace)
	if terraform.WorkspaceSelect(context.Background(), trfWorkspace) != nil {
		tfp.logger.Errorf("error switching Terraform workspace '%s'", trfWorkspace)
		return nil, err
	}

	tfp.logger.Info("Running Terraform Apply....")
	err = terraform.Apply(ctx, tfexec.VarFile(tfvarsTmpFile))
	if err != nil {
		tfp.logger.Error("error terraform apply")

		return nil, err
	}

	out, err := terraform.Output(ctx)
	if err != nil {
		tfp.logger.Error("error terraform output.")
		return nil, err
	}
	outReposBytes, _ := out["container_registry_repositories"].Value.MarshalJSON()
	m.SetBytes(outReposBytes)
	tfp.logger.Infof("Terraform output registry repositories: %s", string(outReposBytes))
	outUserNameBytes, _ := out["container_registry_user_writer_username"].Value.MarshalJSON()
	tfp.logger.Infof("Terraform output registry writer username: %s", string(outUserNameBytes))
	outUserPasswordBytes, _ := out["container_registry_user_writer_password"].Value.MarshalJSON()
	tfp.logger.Infof("Terraform output registry writer password: %s", string(outUserPasswordBytes))

	return []*service.Message{m}, nil
}

func (tfp *TerraformProcessor) Close(ctx context.Context) error {
	return nil
}
