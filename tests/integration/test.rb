# Verificación del puerto 80
describe port(80) do
    it { should be_listening }
  end

# Verificación de la versión de Ubuntu
describe command('lsb_release -a') do
    its('stdout') { should match /Description:\s+Ubuntu\s+20\.04/ } # Ajusta la versión según tus necesidades
  end
  
# Verificación del servicio de mysql
describe service('mysql') do
    it { should be_running }
  end

# Verificación de la versión de PHP
describe command('php --version') do
    its('stdout') { should match /PHP 7\.4\.3/ }
  end
  
# Verifica si el servicio de apache se está ejecutando
control 'apache2-service' do
    impact 0.5
    title 'Apache2 service should be running'
    desc 'Verify that the Apache2 service is running'
    
    describe service('apache2') do
      it { should be_running }
    end
  end
  