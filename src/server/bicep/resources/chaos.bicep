@description('First part of the resource name')
param nameprefix string

@description('Azure region for resources')
param location string = resourceGroup().location
