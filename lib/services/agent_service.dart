import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../config/app_constants.dart';
import '../models/index.dart';

/// Firestore Agent Service for managing agents and their shop registrations
class AgentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Create a new agent
  Future<String> createAgent({
    required String name,
    required String email,
    required String phone,
    double commissionRate = 0.0,
  }) async {
    try {
      _logger.i('Creating agent: $name');

      final now = DateTime.now();
      final agent = Agent(
        agentId: '', // Will be set by Firestore
        name: name,
        email: email,
        phone: phone,
        shopsCount: 0,
        shopIds: [],
        commissionRate: commissionRate,
        totalCommission: 0.0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(AppConstants.agentsCollection)
          .add(agent.toFirestore());

      _logger.i('Agent created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating agent: $e');
      rethrow;
    }
  }

  /// Get agent by ID
  Future<Agent?> getAgentById(String agentId) async {
    try {
      _logger.i('Fetching agent: $agentId');

      final doc = await _firestore
          .collection(AppConstants.agentsCollection)
          .doc(agentId)
          .get();

      if (!doc.exists) {
        _logger.w('Agent not found: $agentId');
        return null;
      }

      return Agent.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching agent: $e');
      rethrow;
    }
  }

  /// Validate agent ID exists and is active
  Future<bool> validateAgentId(String agentId) async {
    try {
      _logger.i('Validating agent ID: $agentId');

      final agent = await getAgentById(agentId);

      if (agent == null) {
        _logger.w('Agent ID validation failed - agent not found: $agentId');
        return false;
      }

      if (!agent.isActive) {
        _logger.w('Agent ID validation failed - agent inactive: $agentId');
        return false;
      }

      _logger.i('Agent ID validation successful: $agentId');
      return true;
    } catch (e) {
      _logger.e('Error validating agent ID: $e');
      return false;
    }
  }

  /// Check if a shop is already registered with an agent ID
  /// Returns true if shop is already registered with this agent
  Future<bool> isShopRegisteredByAgent({
    required String shopId,
    required String agentId,
  }) async {
    try {
      _logger.i('Checking if shop $shopId is already registered with agent $agentId');

      final agent = await getAgentById(agentId);

      if (agent == null) {
        return false;
      }

      final alreadyRegistered = agent.shopIds.contains(shopId);
      _logger.i('Shop registration check: alreadyRegistered=$alreadyRegistered');

      return alreadyRegistered;
    } catch (e) {
      _logger.e('Error checking shop registration: $e');
      return false;
    }
  }

  /// Register a shop to an agent
  /// Increments shop count and adds shop ID to agent's list
  Future<void> registerShopToAgent({
    required String shopId,
    required String agentId,
  }) async {
    try {
      _logger.i('Registering shop $shopId to agent $agentId');

      final agent = await getAgentById(agentId);

      if (agent == null) {
        throw Exception('Agent not found: $agentId');
      }

      if (agent.shopIds.contains(shopId)) {
        throw Exception('Shop already registered with this agent');
      }

      final updatedShopIds = [...agent.shopIds, shopId];
      final newShopsCount = updatedShopIds.length;

      await _firestore
          .collection(AppConstants.agentsCollection)
          .doc(agentId)
          .update({
            'shopIds': updatedShopIds,
            'shopsCount': newShopsCount,
            'updatedAt': Timestamp.now(),
          });

      _logger.i('Shop registered to agent. New shop count: $newShopsCount');
    } catch (e) {
      _logger.e('Error registering shop to agent: $e');
      rethrow;
    }
  }

  /// Get all agents
  Future<List<Agent>> getAllAgents({bool activeOnly = true}) async {
    try {
      _logger.i('Fetching all agents (activeOnly=$activeOnly)');

      Query query = _firestore.collection(AppConstants.agentsCollection);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      final agents = snapshot.docs
          .map((doc) => Agent.fromFirestore(doc))
          .toList();

      _logger.i('Fetched ${agents.length} agents');
      return agents;
    } catch (e) {
      _logger.e('Error fetching all agents: $e');
      rethrow;
    }
  }

  /// Update agent details
  Future<void> updateAgent(Agent agent) async {
    try {
      _logger.i('Updating agent: ${agent.agentId}');

      final updatedAgent = agent.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.agentsCollection)
          .doc(agent.agentId)
          .set(updatedAgent.toFirestore());

      _logger.i('Agent updated: ${agent.agentId}');
    } catch (e) {
      _logger.e('Error updating agent: $e');
      rethrow;
    }
  }

  /// Delete agent (soft delete - mark as inactive)
  Future<void> deleteAgent(String agentId) async {
    try {
      _logger.i('Deleting agent: $agentId');

      await _firestore
          .collection(AppConstants.agentsCollection)
          .doc(agentId)
          .update({
            'isActive': false,
            'updatedAt': Timestamp.now(),
          });

      _logger.i('Agent deleted (marked inactive): $agentId');
    } catch (e) {
      _logger.e('Error deleting agent: $e');
      rethrow;
    }
  }

  /// Get agent stream (real-time updates)
  Stream<Agent?> getAgentStream(String agentId) {
    try {
      _logger.i('Setting up agent stream: $agentId');

      return _firestore
          .collection(AppConstants.agentsCollection)
          .doc(agentId)
          .snapshots()
          .map((doc) => doc.exists ? Agent.fromFirestore(doc) : null);
    } catch (e) {
      _logger.e('Error setting up agent stream: $e');
      rethrow;
    }
  }
}
