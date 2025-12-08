import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/index.dart';
import '../../services/agent_service.dart';

/// Admin Agent Management Screen - Create, edit, delete, and manage agents
class AdminAgentManagementScreen extends StatefulWidget {
  const AdminAgentManagementScreen({super.key});

  @override
  State<AdminAgentManagementScreen> createState() =>
      _AdminAgentManagementScreenState();
}

class _AdminAgentManagementScreenState
    extends State<AdminAgentManagementScreen> {
  late AgentService _agentService;
  final Logger _logger = Logger();
  List<Agent> _agents = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Form controllers for adding/editing agent
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commissionRateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _agentService = AgentService();
    _loadAgents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  /// Load all agents from Firestore
  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agents = await _agentService.getAllAgents(activeOnly: false);
      setState(() {
        _agents = agents;
        _isLoading = false;
      });
      _logger.i('Loaded ${agents.length} agents');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load agents: $e';
        _isLoading = false;
      });
      _logger.e('Error loading agents: $e');
    }
  }

  /// Clear form fields
  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _commissionRateController.clear();
  }

  /// Show add agent dialog
  void _showAddAgentDialog() {
    _clearForm();
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Agent'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Agent Name',
                    hintText: 'Full name of agent',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Name is required';
                    }
                    if (value!.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'agent@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value!)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 (555) 123-4567',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Phone is required';
                    }
                    if (value!.length < 10) {
                      return 'Phone must be at least 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commissionRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commission Rate (%)',
                    hintText: '5.0',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Commission rate is required';
                    }
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0 || rate > 100) {
                      return 'Enter a valid percentage (0-100)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              try {
                await _agentService.createAgent(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  phone: _phoneController.text.trim(),
                  commissionRate: double.parse(_commissionRateController.text),
                );

                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Agent "${_nameController.text}" created successfully!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // Reload agents
                await _loadAgents();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error creating agent: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show edit agent dialog
  void _showEditAgentDialog(Agent agent) {
    _nameController.text = agent.name;
    _emailController.text = agent.email;
    _phoneController.text = agent.phone;
    _commissionRateController.text = agent.commissionRate.toString();
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Agent'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Agent Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commissionRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commission Rate (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'Commission rate is required'; // ignore: curly_braces_in_flow_control_structures
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0 || rate > 100) {
                      return 'Enter a valid percentage (0-100)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              try {
                final updatedAgent = agent.copyWith(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  phone: _phoneController.text.trim(),
                  commissionRate: double.parse(_commissionRateController.text),
                );

                await _agentService.updateAgent(updatedAgent);

                navigator.pop();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Agent updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Reload agents
                await _loadAgents();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error updating agent: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmDialog(Agent agent) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agent?'),
        content: Text(
          'Are you sure you want to delete agent "${agent.name}"?\n\n'
          'This agent has registered ${agent.shopsCount} shops.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _agentService.deleteAgent(agent.agentId);

                navigator.pop();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Agent deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Reload agents
                await _loadAgents();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting agent: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAgentDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.1 * 255).round()),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Summary Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Agents',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _agents.length.toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Shops Registered',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _agents
                                    .fold<int>(
                                      0,
                                      (sum, a) => sum + a.shopsCount,
                                    )
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Agents List
                  const Text(
                    'Agents List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_agents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No agents yet. Tap + to create one.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _agents.length,
                      itemBuilder: (context, index) {
                        final agent = _agents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                agent.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(agent.name),
                            subtitle: Text(agent.email),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message:
                                        '${agent.shopsCount} shops registered',
                                    child: Chip(
                                      label: Text(
                                        agent.shopsCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditAgentDialog(agent);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmDialog(agent);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => _showAgentDetails(agent),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  /// Show agent details bottom sheet
  void _showAgentDetails(Agent agent) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    agent.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(child: Text(agent.name[0].toUpperCase())),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Email', agent.email),
              _detailRow('Phone', agent.phone),
              _detailRow('Status', agent.isActive ? 'Active' : 'Inactive'),
              _detailRow('Commission Rate', '${agent.commissionRate}%'),
              _detailRow('Shops Registered', agent.shopsCount.toString()),
              _detailRow(
                'Total Commission',
                'Rs ${agent.totalCommission.toStringAsFixed(2)}',
              ),
              _detailRow(
                'Member Since',
                '${agent.createdAt.day}/${agent.createdAt.month}/${agent.createdAt.year}',
              ),
              const SizedBox(height: 16),
              if (agent.shopIds.isNotEmpty) ...[
                const Text(
                  'Registered Shops',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...agent.shopIds.map(
                  (shopId) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $shopId'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for detail rows
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
