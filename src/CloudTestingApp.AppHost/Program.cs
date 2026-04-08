var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithLifetime(ContainerLifetime.Persistent);

var db = postgres.AddDatabase("cloudtestingapp");

builder.AddProject<Projects.CloudTestingApp_Api>("api")
    .WithReference(db)
    .WaitFor(db)
    .WithExternalHttpEndpoints();

builder.Build().Run();
